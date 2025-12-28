#include "OtaBackend.h"
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <cstdlib>
#include <iostream>
#include <chrono>
#include <fstream>
#include <thread>
#include <sys/statvfs.h>
#include <cstdio>
#include <cstring>


static const size_t CHUNK_SIZE = 64 * 1024;

static void ensureClientDir()

{
    struct stat st;
    if (stat(DATA_CLIENT_PATH, &st) != 0) {
        mkdir(DATA_CLIENT_PATH, 0777);
    }
    struct stat vf;
    if (stat(UPDATE_VERSION_PATH, &vf) != 0) {
        std::ofstream versionFile(UPDATE_VERSION_PATH);
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

/*
 * ==============================================================
 * Callback function provided for the UI Controller
 * ==============================================================
 */

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

void OtaBackend::setSystemInfoCallback(SystemInfoCallback cb){
    std::lock_guard<std::mutex> lk(systemInfoCbMutex_);
    systemInfoCb_ = std::move(cb);
}

/*
 * ==============================================================
 * bool init()
 * ==============================================================
 * Initializes the OTA Backend
 * Prepares filesystem
 * Initializes CommonAPI runtime
 * Builds and validates SOME/IP Proxy (ensures server is connected)
 * Subscribes to file transfer event.
 * Starts system monitoring thread
 */

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

        using clock = std::chrono::steady_clock;
        auto nextPoll = clock::now();

        const auto pollInterval = std::chrono::seconds(1);

        while (running_) {
            const auto now = clock::now();

            if(now >= nextPoll){
                pollSystemInfoOnce();
                nextPoll = now + pollInterval;
            }
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

/*
 * ==============================================================
 * bool requestUpdate(uint32_t currentVersion)
 * ==============================================================
 * Sends a synchronous SOME/IP RPC to query update metadata
 * Result depends on the clients current version
 * Server provides SystemInfo for future use
 */
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


/*
 * ==============================================================
 * bool startDownload()
 * ==============================================================
 * Sends a request via SOME/IP to begin streaming the update file via events
 * This function only initiates the transfer
 * Actual devlivery data is handled asynchronously via onChunk()
 */
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

/*
 * ==============================================================
 * void onChunk(uint32_t index, const CommonAPI::ByteBuffer& data, bool lastChunk)
 * ==============================================================
 * Called for each file chunk recieved via SOME/IP
 * Appends chunk data to the output file
 * Updates progress
 * Signals completion when the last chunk is recieved
 * The last chunk is application-level signal indicating end-of-transfer
 */

void OtaBackend::onChunk(uint32_t index,
                         const CommonAPI::ByteBuffer& data,
                         bool lastChunk) {
    static std::ofstream ofs;

    if (!ofs.is_open()) {
        std::string path = DATA_CLIENT_PATH + outputFilename_;
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

// System Info Helper functions

/*
 * ==============================================================
 * bool readProcStatCpu(uint64_t&, uint64_t&)
 * ==============================================================
 * Reads cumulative CPU time counters from /proc/stat.
 * The returned values are monotonic since boot and must be differenced
 * accrss samples to compute CPU usage.
 */
bool OtaBackend::readProcStatCpu(uint64_t& idle, uint64_t& total) {
    FILE* f = std::fopen("/proc/stat", "r");
    if(!f) return false;

    char line[512];

    if(!std::fgets(line, sizeof(line), f)){
        std::fclose(f);
        return false;
    }

    std::fclose(f);

    char cpuLabel[8];
    uint64_t user=0,nice=0,system=0,idleVal=0,iowait=0,irq=0,softirq=0,steal=0,guest=0,guestNice=0;

    int n = std::sscanf(line, "%7s %lu %lu %lu %lu %lu %lu %lu %lu %lu %lu",
                                cpuLabel, &user, &nice, &system, &idleVal, &iowait, &irq,
                        &softirq, &steal, &guest, &guestNice);

    if(n < 5) return false;

    idle = idleVal + iowait;
    total = user + nice + system + idleVal + iowait + irq + softirq + steal;
    return true;
}

/*
 * ==============================================================
 * bool readProcMeminfo(uint64_t, uint64_t)
 * ==============================================================
 * Reads total and available system memory from /proc/meminfo
 * Uses MemAvailable
 */
bool OtaBackend::readProcMeminfo(uint64_t& memTotalBytes, uint64_t& memAvailBytes){
    FILE* f = std::fopen("/proc/meminfo", "r");
    if(!f) return false;

    char key[64];
    uint64_t valueKb = 0;
    char unit[32];

    memTotalBytes = 0;
    memAvailBytes = 0;

    while(std::fscanf(f, "%63s %lu %31s\n", key, &valueKb, unit) == 3) {
        if(std::strcmp(key, "MemTotal:") == 0) {
            memTotalBytes = valueKb * 1024ULL;
        }else if (std::strcmp(key, "MemAvailable:") == 0) {
            memAvailBytes = valueKb * 1024ULL;
        }

        if(memTotalBytes && memAvailBytes) break;
    }

    std::fclose(f);
    return (memTotalBytes > 0);
}

bool OtaBackend::readStorageStatvfs(const std::string& path,
                                    uint64_t& totalBytes,
                                    uint64_t& usedBytes) {
    struct statvfs vfs;
    if (statvfs(path.c_str(), &vfs) != 0) return false;

    const uint64_t blockSize = static_cast<uint64_t>(vfs.f_frsize);
    const uint64_t total = static_cast<uint64_t>(vfs.f_blocks) * blockSize;
    const uint64_t free = static_cast<uint64_t>(vfs.f_bfree) * blockSize;
    const uint64_t used = (total >= free) ? (total - free) : 0;

    totalBytes = total;
    usedBytes = used;
    return true;
}

bool OtaBackend::readTemperature(double& tempC) {
    // /sys/class/thermal/thermal_zone0/temp -> millidegrees C
    FILE* f = std::fopen("/sys/class/thermal/thermal_zone0/temp", "r");
    if (!f) return false;

    long milli = 0;
    int n = std::fscanf(f, "%ld", &milli);
    std::fclose(f);

    if (n != 1) return false;
    tempC = static_cast<double>(milli) / 1000.0;
    return true;
}


/*
 * ==============================================================
 * void pollSystemInfoOnce()
 * ==============================================================
 * Collects a snapshot of system metrics (CPU, memory, storage, temp, uptime)
 * Publishes systemInfo the system info callback.
 */

void OtaBackend::pollSystemInfoOnce() {
    SystemInfoSnapshot snap;

    // timestamp (ms)
    const auto now = std::chrono::steady_clock::now().time_since_epoch();
    snap.timestampMs = static_cast<uint64_t>(
        std::chrono::duration_cast<std::chrono::milliseconds>(now).count()
        );

    // CPU%
    uint64_t idle=0,total=0;
    if (readProcStatCpu(idle, total)) {
        if (hasLastCpuSample_) {
            const uint64_t idleDelta = idle - lastCpuIdle_;
            const uint64_t totalDelta = total - lastCpuTotal_;

            if (totalDelta > 0) {
                const double usage = 100.0 * (1.0 - (double)idleDelta / (double)totalDelta);
                int pct = (int)(usage + 0.5);
                if (pct < 0) pct = 0;
                if (pct > 100) pct = 100;
                snap.cpuPercent = pct;
            }
        }
        lastCpuIdle_ = idle;
        lastCpuTotal_ = total;
        hasLastCpuSample_ = true;
    }

            // Memory
    uint64_t memTotal=0, memAvail=0;
    if (readProcMeminfo(memTotal, memAvail)) {
        snap.memTotalBytes = memTotal;
        snap.memUsedBytes = (memTotal >= memAvail) ? (memTotal - memAvail) : 0;
    }

            // Storage
    uint64_t stTotal=0, stUsed=0;
    if (readStorageStatvfs("/", stTotal, stUsed)) {
        snap.storageTotalBytes = stTotal;
        snap.storageUsedBytes = stUsed;
    }

            // Temperature
    double tempC = 0.0;
    if (readTemperature(tempC)) {
        snap.temperatureC = tempC;
    }

    // uptime
    uint64_t upSec = 0;
    if (readProcUptime(upSec)) {
        snap.uptimeSeconds = upSec;
    }


            // Push to controller if callback exists
    SystemInfoCallback cbCopy;
    {
        std::lock_guard<std::mutex> lk(systemInfoCbMutex_);
        cbCopy = systemInfoCb_;
    }
    if (cbCopy) cbCopy(snap);
}


bool OtaBackend::readProcUptime(uint64_t& uptimeSeconds) {
    static bool initialized = false;
    static uint64_t baseUptime = 0;
    static struct timespec baseTime {};

    if (!initialized) {
        FILE* f = std::fopen("/proc/uptime", "r");
        if (!f)
            return false;

        double up = 0.0;
        if (std::fscanf(f, "%lf", &up) != 1) {
            std::fclose(f);
            return false;
        }

        std::fclose(f);

        baseUptime = static_cast<uint64_t>(up);
        clock_gettime(CLOCK_MONOTONIC, &baseTime);

        initialized = true;
    }

    struct timespec now {};
    clock_gettime(CLOCK_MONOTONIC, &now);

    uint64_t elapsed =
        static_cast<uint64_t>(now.tv_sec - baseTime.tv_sec);

    uptimeSeconds = baseUptime + elapsed;
    return true;
}










