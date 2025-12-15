#ifndef OTACONTROLLER_H
#define OTACONTROLLER_H

#include <qthread.h>
#include <QObject>
#include <QString>
#include <atomic>
#include <memory>
#include <thread>

#include "OtaBackend.h"

class OtaBackend;

class OtaController : public QObject {
    Q_OBJECT

    Q_PROPERTY(int progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(bool busy READ isBusy NOTIFY busyChanged)

   public:
    explicit OtaController(QObject* parent = nullptr);
    ~OtaController();

    int progress() const;
    bool isBusy() const;

    Q_INVOKABLE void initialize();
    Q_INVOKABLE void checkForUpdate();
    Q_INVOKABLE void startDownload();

   signals:
    void progressChanged(int percent);
    void updateCheckDone(bool available);
    void downloadRejected();
    void busyChanged();
    void updateAvailable(bool available);
    void downloadFinished(bool success);
    void errorOccurred(const QString& message);

   private:
    //void setProgress(int value);
    void setBusy(bool value);
    void runAsync(std::function<void()> task);

   private:
    std::unique_ptr<OtaBackend> backend_;

    std::thread backendThread_;
    std::mutex backendMutex_;

    std::atomic<bool> busy_{false};
    std::atomic<int> progress_{0};
};

#endif // OTACONTROLLER_H

