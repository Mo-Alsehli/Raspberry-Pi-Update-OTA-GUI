#include "OtaBackend.h"
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <cstdlib>
#include <iostream>
#include <chrono>
#include <fstream>
#include <thread>


static const size_t CHUNK_SIZE = 64 * 1024;

static void ensureClientDir() {
    struct stat st;
    if (stat("/home/root/rpi-update-ota/data/client", &st) != 0) {
        mkdir("/home/root/rpi-update-ota/data/client", 0777);
    }
    struct stat vf;
    if (stat("/home/root/rpi-update-ota/data/client/update.version", &vf) != 0) {
        std::ofstream versionFile("/home/root/rpi-update-ota/data/client/update.version");
        if (versionFile.is_open()) {
            versionFile << "0";
            versionFile.close();
        }
    }
}

OtaBackend::OtaBackend(const std::string& outputFilename)
    : outputFilename_(outputFilename), running_(false) {}

OtaBackend::~OtaBackend() {
    stop();
}

void OtaBackend::setProgressCallback(ProgressCallback cb){
    progressCb_ = std::move(cb);
}

void OtaBackend::setFinishedCallback(FinishedCallback cb){
    finishedCb_ = std::move(cb);
}

void OtaBackend::setErrorCallback(ErrorCallback cb){
    errorCb_ = std::move(cb);
}

void OtaBackend::setChunkCallback(ChunkCallback cb) {
    chunkCb_ = std::move(cb);
}

bool OtaBackend::init() {
    ensureClientDir();


    // Set library base for CommonAPI
    CommonAPI::Runtime::setProperty("LibraryBase", "FileTransfer");

    runtime_ = CommonAPI::Runtime::get();
    if (!runtime_) {
        std::cerr << "[Backend] Failed to get runtime\n";
        return false;
    }

    std::cout << "[Backend] Building proxy...\n";

    // Keep trying to build proxy
    const int maxRetries = 30;
    for (int i = 0; i < maxRetries; ++i) {
        proxy_ = runtime_->buildProxy<ft::FileTransferProxy>(
            "local",
            "filetransfer.example.FileTransfer",
            "client-sample");

        if (proxy_) {
            std::cout << "[Backend] Proxy built successfully\n";
            break;
        }

        std::cout << "[Backend] Proxy build attempt " << (i+1) << "/" << maxRetries << "\n";
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }

    if (!proxy_) {
        std::cerr << "[Backend] Failed to build proxy after retries\n";
        if (errorCb_) errorCb_("Failed to build proxy");
        return false;
    }

    // Wait for service availability (like your standalone app)
    std::cout << "[Backend] Waiting for service availability...\n";
    const int timeoutSec = 30;
    bool available = false;

    for (int i = 0; i < timeoutSec; ++i) {
        if (proxy_->isAvailable()) {
            available = true;
            std::cout << "[Backend] Service available after " << i << " seconds\n";
            break;
        }
        std::cout << "[Backend] Waiting... (" << (i+1) << "/" << timeoutSec << ")\n";
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }

    if (!available) {
        std::cerr << "[Backend] Service not available after timeout\n";
        if (errorCb_) {
            errorCb_("Service not available. Ensure server is running.");
        }
        return false;
    }

    // Subscribe to file chunk events
    proxy_->getFileChunkEvent().subscribe(
        [this](uint32_t index,
               const CommonAPI::ByteBuffer& data,
               bool last) {
            std::cout << "[Backend] Received chunk " << index
                      << " size=" << data.size()
                      << " last=" << last << "\n";
            onChunk(index, data, last);
        });

    std::cout << "[Backend] Subscribed to FileChunkEvent\n";

    // Start event loop thread (for processing callbacks)
    running_ = true;
    eventThread_ = std::thread([this]() {
        std::cout << "[Backend] Event loop thread started\n";
        while (running_) {
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
        std::cout << "[Backend] Event loop thread stopped\n";
    });

    return true;
}

void OtaBackend::stop() {
    running_ = false;
    if (eventThread_.joinable()) {
        eventThread_.join();
    }
}

bool OtaBackend::requestUpdate(uint32_t currentVersion) {
    if (!proxy_) {
        std::cerr << "[Backend] Proxy not initialized\n";
        if (errorCb_) {
            errorCb_("Backend not initialized");
        }
        return false;
    }

    if (!proxy_->isAvailable()) {
        std::cerr << "[Backend] Service not available for requestUpdate\n";
        if (errorCb_) {
            errorCb_("Service not available");
        }
        return false;
    }

    std::cout << "[Backend] Calling requestUpdate with version " << currentVersion << "\n";

    CommonAPI::CallStatus status;
    proxy_->requestUpdate(currentVersion, status, updateInfo_);

    std::cout << "[Backend] requestUpdate status: " << static_cast<int>(status) << "\n";

    if(status != CommonAPI::CallStatus::SUCCESS){
        std::cerr << "[Backend] requestUpdate failed with status " << static_cast<int>(status) << "\n";
        if(errorCb_) {
            errorCb_("requestUpdate() failed - call status: " + std::to_string(static_cast<int>(status)));
        }
        return false;
    }

    std::cout << "[Backend] Update info - size: " << updateInfo_.getSize() << "\n";

    return true;
}

bool OtaBackend::startDownload() {
    if (!proxy_ || !proxy_->isAvailable()) {
        if (errorCb_) {
            errorCb_("Service not available for download");
        }
        return false;
    }

    std::cout << "[Backend] Starting download for: " << outputFilename_ << "\n";

    CommonAPI::CallStatus status;
    bool accepted = false;
    proxy_->startTransfer(outputFilename_, status, accepted);

    std::cout << "[Backend] startTransfer status: " << static_cast<int>(status)
              << " accepted: " << accepted << "\n";

    if(status != CommonAPI::CallStatus::SUCCESS || !accepted){
        std::cerr << "[Backend] startTransfer rejected\n";
        if(errorCb_){
            errorCb_("startTransfer() rejected by server");
        }
        return false;
    }

    return true;
}

void OtaBackend::onChunk(uint32_t index,
                         const CommonAPI::ByteBuffer& data,
                         bool lastChunk) {
    static std::ofstream ofs;

    if (!ofs.is_open()) {
        std::string path = "/home/root/rpi-update-ota/data/client/" + outputFilename_;
        std::cout << "[Backend] Opening file: " << path << "\n";
        ofs.open(path.c_str(), std::ios::binary);
        if(!ofs.is_open()){
            std::cerr << "[Backend] Failed to open output file: " << path << "\n";
            if(errorCb_){
                errorCb_("Failed to open output file");
            }
            return;
        }

    }

    ofs.write(reinterpret_cast<const char*>(data.data()),
              static_cast<std::streamsize>(data.size()));

    if(updateInfo_.getSize() > 0 && progressCb_){
        double progress =
            (static_cast<double>(index * CHUNK_SIZE) /
             static_cast<double>(updateInfo_.getSize())) * 100.0;
        progressCb_(static_cast<int>(progress));
    }

    if (lastChunk) {
        std::cout << "[Backend] Last chunk received, closing file\n";
        ofs.close();
        if(finishedCb_){
            finishedCb_();
        }
    }

    uint32_t totalChunks =
        static_cast<uint32_t>(
            (updateInfo_.getSize() + CHUNK_SIZE - 1) / CHUNK_SIZE
            );

    if (chunkCb_) {
        chunkCb_(index, totalChunks);
    }
}

uint64_t OtaBackend::updateSize() const {
    return updateInfo_.getSize();
}

bool OtaBackend::isServerAvailable() const {
    return proxy_ && proxy_->isAvailable();
}


