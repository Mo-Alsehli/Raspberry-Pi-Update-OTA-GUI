// OtaController.cpp

#include "OtaController.h"
#include "OtaBackend.h"

#include <chrono>

// ------------------------------------------------------------
// Helper: read uint32 from a text file
// ------------------------------------------------------------
static bool readUint32FromFile(const QString& path, uint32_t& valueOut) {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return false;

    QTextStream in(&file);
    const QString line = in.readLine().trimmed();
    if (line.isEmpty())
        return false;

    bool ok = false;
    if (line.startsWith("0x", Qt::CaseInsensitive))
        valueOut = line.toUInt(&ok, 16);
    else
        valueOut = line.toUInt(&ok, 10);

    return ok;
}

OtaController::OtaController(QObject* parent)
    : QObject(parent),
      backend_(std::make_unique<OtaBackend>("rpi4-update.wic")) {

    // ---- Backend → Qt bridge (progress + speed) ----
    backend_->setProgressCallback([this](int percent) {
        const auto now = std::chrono::steady_clock::now();

                // Ensure downloadStart_ is initialized at the beginning of a transfer
        if (percent <= 0 || downloadStart_ == std::chrono::steady_clock::time_point{}) {
            downloadStart_ = now;
            speed_ = 0.0;
        } else {
            const double elapsedSec =
                std::chrono::duration<double>(now - downloadStart_).count();

            if (elapsedSec > 0.0 && backend_) {
                const double totalMB = backend_->updateSize() / (1024.0 * 1024.0);
                const double downloadedMB = (percent / 100.0) * totalMB;
                speed_ = downloadedMB / elapsedSec;
            }
        }

        QMetaObject::invokeMethod(
            this,
            [this, percent]() {
                progress_ = percent;
                emit progressChanged(percent);
                emit speedChanged(speed_.load());
            },
            Qt::QueuedConnection
            );
    });

    backend_->setFinishedCallback([this]() {
        QMetaObject::invokeMethod(
            this,
            [this]() {
                setBusy(false);
                emit downloadFinished(true);
            },
            Qt::QueuedConnection
            );
    });

    backend_->setErrorCallback([this](const std::string& msg) {
        QMetaObject::invokeMethod(
            this,
            [this, msg]() {
                setBusy(false);
                updateServerConnected();
                emit errorOccurred(QString::fromStdString(msg));
            },
            Qt::QueuedConnection
            );
    });

            // ---- Backend → Qt bridge (chunk info) ----
    backend_->setChunkCallback([this](uint32_t index, uint32_t total) {
        QMetaObject::invokeMethod(
            this,
            [this, index, total]() {
                totalChunks_ = static_cast<int>(total);
                chunksReceived_ = static_cast<int>(index + 1);
                emit chunkInfoChanged();
            },
            Qt::QueuedConnection
            );
    });
}

OtaController::~OtaController() = default;

bool OtaController::isBusy() const {
    return busy_.load();
}

int OtaController::progress() const {
    return progress_.load();
}

double OtaController::speedMBps() const {
    return speed_.load();
}

bool OtaController::serverConnected() const {
    return serverConnected_.load();
}

int OtaController::totalChunks() const {
    return totalChunks_.load();
}

int OtaController::chunksReceived() const {
    return chunksReceived_.load();
}

uint64_t OtaController::totalSize() const {
    return backend_ ? backend_->updateSize() : 0;
}

void OtaController::setBusy(bool value) {
    busy_ = value;
    emit busyChanged();
}

void OtaController::updateServerConnected() {
    const bool connected = backend_ && backend_->isServerAvailable();
    if (serverConnected_ != connected) {
        serverConnected_ = connected;
        emit serverConnectedChanged(connected);
    }
}

void OtaController::runAsync(std::function<void()> task) {
    if (busy_) return;

    setBusy(true);

    std::thread([task, this]() {
        task();
    }).detach();
}

void OtaController::initialize() {
    runAsync([this]() {
        // Read current version (fallback to 0 if missing/invalid)
        uint32_t version = 0;
        const QString versionPath =
            "/home/root/rpi-update-ota/data/client/update.version";

        if (!readUint32FromFile(versionPath, version)) {
            version = 0;
            qWarning() << "[OtaController] Failed to read version file:" << versionPath
                       << "-> using 0";
        }
        currentVersion_ = version;

        const bool ok = backend_->init();

        QMetaObject::invokeMethod(this, [this, ok]() {
            setBusy(false);
            updateServerConnected();

            if (!ok) {
                emit errorOccurred("Backend init failed");
            }
        }, Qt::QueuedConnection);
    });
}

void OtaController::checkForUpdate() {
    runAsync([this]() {

        QMetaObject::invokeMethod(this, [this]() {
            emit updateCheckStarted();
            updateServerConnected();
        }, Qt::QueuedConnection);

        if (!backend_->requestUpdate(currentVersion_)) {
            QMetaObject::invokeMethod(this, [this]() {
                setBusy(false);
                updateServerConnected();
                emit errorOccurred("requestUpdate failed");
            }, Qt::QueuedConnection);
            return;
        }

        if(!(backend_->updateSize() > 0) || (backend_->updateInfo_.getResultCode() != 0)) {
            updateRequest = ERROR;
        }else if(!(backend_->updateInfo_.getIsNew())) {
            updateRequest = UpToDate;
        }else {
            updateRequest = Available;
        }

        QMetaObject::invokeMethod(this, [this]() {
            setBusy(false);
            emit totalSizeChanged();
            emit updateCheckDone(updateRequest);
        }, Qt::QueuedConnection);
    });
}

void OtaController::startDownload() {
    runAsync([this]() {

        // Reset UI-visible transfer stats at the start of a new download
        QMetaObject::invokeMethod(this, [this]() {
            updateServerConnected();

            progress_ = 0;
            speed_ = 0.0;
            downloadStart_ = std::chrono::steady_clock::time_point{};

            totalChunks_ = 0;
            chunksReceived_ = 0;

            emit progressChanged(0);
            emit speedChanged(0.0);
            emit chunkInfoChanged();
        }, Qt::QueuedConnection);

                // Up-to-date guard: no download if server reported size==0
        if (backend_->updateSize() == 0) {
            QMetaObject::invokeMethod(this, [this]() {
                setBusy(false);
                emit downloadRejected();
            }, Qt::QueuedConnection);
            return;
        }

        if (!backend_->startDownload()) {
            QMetaObject::invokeMethod(this, [this]() {
                setBusy(false);
                updateServerConnected();
                emit downloadRejected();
            }, Qt::QueuedConnection);
            return;
        }

                // Success: keep busy=true until finished/error callback clears it.
    });
}
