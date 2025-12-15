#include "OtaController.h"
#include "OtaBackend.h"

#include <QMetaObject>

OtaController::OtaController(QObject* parent)
    : QObject(parent),
      backend_(std::make_unique<OtaBackend>("qnx_uefi.iso")) {

    // ---- Backend → Qt bridge ----
    backend_->setProgressCallback([this](int percent) {
        QMetaObject::invokeMethod(
            this,
            [this, percent]() {
                progress_ = percent;
                emit progressChanged(percent);
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
                emit errorOccurred(QString::fromStdString(msg));
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

void OtaController::setBusy(bool value) {
    busy_ = value;
    emit busyChanged();
}

void OtaController::runAsync(std::function<void()> task) {
    if (busy_) {
        return;
    }

    setBusy(true);

    std::thread([task, this]() {
        //std::lock_guard<std::mutex> lock(backendMutex_);
        task();
    }).detach();
}

void OtaController::initialize() {
    runAsync([this]() {
        const bool ok = backend_->init();

        QMetaObject::invokeMethod(this, [this, ok]() {
            setBusy(false);
            if (!ok) {
                emit errorOccurred("Backend init failed");
            }
        }, Qt::QueuedConnection);
    });
}


void OtaController::checkForUpdate() {
    runAsync([this]() {
        uint32_t currentVersion = 1;

        if (!backend_->requestUpdate(currentVersion)) {
            QMetaObject::invokeMethod(this, [this]() {
                setBusy(false);
                emit errorOccurred("requestUpdate failed");
            }, Qt::QueuedConnection);
            return;
        }

        const bool available = (backend_->updateSize() > 0);

        QMetaObject::invokeMethod(this, [this, available]() {
            setBusy(false);
            emit updateCheckDone(available);
        }, Qt::QueuedConnection);

    });
}

void OtaController::startDownload() {
    runAsync([this]() {
        if (!backend_->startDownload()) {
            QMetaObject::invokeMethod(this, [this]() {
                setBusy(false);
                emit downloadRejected();
            }, Qt::QueuedConnection);
            return;
        }
    });
}
