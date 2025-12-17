#ifndef OTACONTROLLER_H
#define OTACONTROLLER_H

#include <qthread.h>
#include <QObject>
#include <QString>
#include <atomic>
#include <memory>
#include <thread>
#include <QFile>
#include <QTextStream>
#include <QDebug>
#include <chrono>
#include <QMetaObject>




#include "OtaBackend.h"

class OtaBackend;

enum CheckUpdateState {
    Available,
    UpToDate,
    ERROR
};

// helper


class OtaController : public QObject {
    Q_OBJECT

    Q_PROPERTY(int progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(bool busy READ isBusy NOTIFY busyChanged)
    Q_PROPERTY(bool serverConnected READ serverConnected NOTIFY serverConnectedChanged)
    Q_PROPERTY(uint64_t totalSize READ totalSize NOTIFY totalSizeChanged)
    Q_PROPERTY(double speedMBps READ speedMBps NOTIFY speedChanged)
    Q_PROPERTY(int totalChunks READ totalChunks NOTIFY chunkInfoChanged)
    Q_PROPERTY(int chunksReceived READ chunksReceived NOTIFY chunkInfoChanged)


   public:
    explicit OtaController(QObject* parent = nullptr);
    ~OtaController();

    int progress() const;
    bool isBusy() const;
    bool isServerAvailable() const;
    bool serverConnected() const;
    void updateServerConnected();
    uint64_t totalSize() const;
    double speedMBps() const;
    int totalChunks() const;
    int chunksReceived() const;



    Q_INVOKABLE void initialize();
    Q_INVOKABLE void checkForUpdate();
    Q_INVOKABLE void startDownload();

   signals:
    void progressChanged(int percent);
    void updateCheckDone(CheckUpdateState);
    void downloadRejected();
    void busyChanged();
    void updateAvailable(bool available);
    void downloadFinished(bool success);
    void errorOccurred(const QString& message);
    void serverConnectedChanged(bool connected);
    void updateCheckStarted();
    void totalSizeChanged();
    void speedChanged(double speed);
    void chunkInfoChanged();


   private:
    //void setProgress(int value);
    void setBusy(bool value);
    void runAsync(std::function<void()> task);

   private:
    uint32_t currentVersion_{0};

    std::unique_ptr<OtaBackend> backend_;

    std::thread backendThread_;
    std::mutex backendMutex_;

    std::atomic<bool> busy_{false};
    std::atomic<int> progress_{0};
    std::atomic<bool> serverConnected_{false};
    std::atomic<double> speed_{0.0};
    std::atomic<int> totalChunks_{0};
    std::atomic<int> chunksReceived_{0};

    CheckUpdateState updateRequest;


    std::chrono::steady_clock::time_point downloadStart_;

};

#endif // OTACONTROLLER_H

