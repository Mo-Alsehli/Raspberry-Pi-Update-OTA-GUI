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

namespace ft = v0::filetransfer::example;

class OtaBackend {
   public:
    using ProgressCallback = std::function<void(int)>;
    using FinishedCallback = std::function<void()>;
    using ErrorCallback = std::function<void(const std::string&)>;
    using ChunkCallback = std::function<void(uint32_t index, uint32_t totalChunks)>;

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

    std::string outputFilename_;
    std::shared_ptr<CommonAPI::Runtime> runtime_;
    std::shared_ptr<ft::FileTransferProxy<>> proxy_;
    ft::FileTransfer::UpdateInfo updateInfo_;


   private:
    void onChunk(uint32_t index,
                 const CommonAPI::ByteBuffer& data,
                 bool lastChunk);

   private:

    ProgressCallback progressCb_;
    FinishedCallback finishedCb_;
    ErrorCallback errorCb_;
    ChunkCallback chunkCb_;

    std::thread eventThread_;
    std::atomic<bool> running_;
};

#endif  // OTABACKEND_H
