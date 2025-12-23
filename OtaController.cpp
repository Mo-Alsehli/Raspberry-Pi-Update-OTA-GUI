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

    // System Info
    backend_->setSystemInfoCallback([this](const OtaBackend::SystemInfoSnapshot& snap){
        QMetaObject::invokeMethod(
            this,
            [this, snap](){
                cpuPercent_ = snap.cpuPercent;
                memUsed_ = snap.memUsedBytes;
                memTotal_ = snap.memTotalBytes;
                stUsed_ = snap.storageUsedBytes;
                stTotal_ = snap.storageTotalBytes;
                temperatureC_ = snap.temperatureC;
                upTimeSeconds_ = snap.uptimeSeconds;

                emit systemInfoChanged();
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

// System Info

int OtaController::cpuPercent() const {
    return cpuPercent_.load();
}

double OtaController::temperatureC() const {
    return temperatureC_.load();
}



static QString formatBytesPair(uint64_t used, uint64_t total, bool asGB) {
    auto toUnit = [asGB](uint64_t b) -> double {
        if (asGB) return b / (1024.0 * 1024.0 * 1024.0);
        return b / (1024.0 * 1024.0);
    };

    const double u = toUnit(used);
    const double t = toUnit(total);

    if (asGB)
        return QString("%1/%2 GB").arg(u, 0, 'f', 1).arg(t, 0, 'f', 1);
    else
        return QString("%1/%2 MB").arg(u, 0, 'f', 0).arg(t, 0, 'f', 0);
}

QString OtaController::memoryText() const {
    return formatBytesPair(memUsed_.load(), memTotal_.load(), false);
}

QString OtaController::storageText() const {
    return formatBytesPair(stUsed_.load(), stTotal_.load(), true);
}

static QString formatUptime(uint64_t totalSeconds)
{
    uint64_t days    = totalSeconds / 86400;
    totalSeconds    %= 86400;

    uint64_t hours   = totalSeconds / 3600;
    totalSeconds    %= 3600;

    uint64_t minutes = totalSeconds / 60;

    char buffer[64];
    std::snprintf(buffer, sizeof(buffer),
                  "%llu d %02llu h %02llu m",
                  (unsigned long long)days,
                  (unsigned long long)hours,
                  (unsigned long long)minutes);

    return QString(buffer);
}

QString OtaController::upTimeText() const {
    return formatUptime(upTimeSeconds_.load());
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
        const QString versionPath = UPDATE_VERSION_PATH;

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
