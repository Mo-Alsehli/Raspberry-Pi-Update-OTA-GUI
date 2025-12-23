#ifndef OTABACKEND_H
#define OTABACKEND_H

#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include <CommonAPI/CommonAPI.hpp>
#include <v0/filetransfer/example/FileTransferProxy.hpp>
#include <cstdint>
#include <memory>
#include <string>
#include <functional>
#include <thread>
#include <atomic>
#include <mutex>
#include <ctime>

#define UBUNTU_PLATFORM 0

#if UBUNTU_PLATFORM == 1
    #define OTA_ROOT "/home/mmagdi/workspace/QT6_Projects/qnxOta/"
#else
    #define OTA_ROOT "/home/root/rpi-update-ota/"
#endif

#define UPDATE_VERSION_PATH OTA_ROOT "update.version"
#define DATA_CLIENT_PATH OTA_ROOT "data/client"



namespace ft = v0::filetransfer::example;


class OtaBackend {
   public:
    using ProgressCallback = std::function<void(int)>;
    using FinishedCallback = std::function<void()>;
    using ErrorCallback = std::function<void(const std::string&)>;
    using ChunkCallback = std::function<void(uint32_t index, uint32_t totalChunks)>;

    // System Info Struct
    struct SystemInfoSnapshot {
        int cpuPercent = 0;                // 0..100
        uint64_t memUsedBytes = 0;
        uint64_t memTotalBytes = 0;
        uint64_t storageUsedBytes = 0;
        uint64_t storageTotalBytes = 0;
        double temperatureC = 0.0;
        uint64_t uptimeSeconds = 0;

        uint64_t timestampMs = 0;
    };

    using SystemInfoCallback = std::function<void(const SystemInfoSnapshot&)>;

    explicit OtaBackend(const std::string& outputFilename);
    ~OtaBackend();

    bool init();
    void stop();
    bool requestUpdate(uint32_t currentVersion);
    bool startDownload();
    uint64_t updateSize() const;
    bool isServerAvailable() const;
    ft::FileTransfer::UpdateInfo updateInfo() const;

    // callback setters (called by controller)
    void setProgressCallback(ProgressCallback cb);
    void setFinishedCallback(FinishedCallback cb);
    void setErrorCallback(ErrorCallback cb);
    void setChunkCallback(ChunkCallback cb);
    void setSystemInfoCallback(SystemInfoCallback cb);

    std::string outputFilename_;
    std::shared_ptr<CommonAPI::Runtime> runtime_;
    std::shared_ptr<ft::FileTransferProxy<>> proxy_;
    ft::FileTransfer::UpdateInfo updateInfo_;


   private:
    void onChunk(uint32_t index,
                 const CommonAPI::ByteBuffer& data,
                 bool lastChunk);

    void pollSystemInfoOnce();
    static bool readProcStatCpu(uint64_t& idle, uint64_t& total);
    static bool readProcMeminfo(uint64_t& memTotalBytes, uint64_t& memAvailBytes);
    static bool readStorageStatvfs(const std::string& path,
                                  uint64_t& totalBytes,
                                   uint64_t& usedBytes);
    static bool readTemperature(double& tempC);
    static bool readProcUptime(uint64_t& uptimeSeconds);

   private:

    ProgressCallback progressCb_;
    FinishedCallback finishedCb_;
    ErrorCallback errorCb_;
    ChunkCallback chunkCb_;

    SystemInfoCallback systemInfoCb_;
    std::mutex systemInfoCbMutex_;

    uint64_t lastCpuIdle_ = 0;
    uint64_t lastCpuTotal_ = 0;
    bool hasLastCpuSample_ = false;

    std::thread eventThread_;
    std::atomic<bool> running_;
};

#endif  // OTABACKEND_H
