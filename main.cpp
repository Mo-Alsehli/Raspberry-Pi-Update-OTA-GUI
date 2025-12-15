#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "OtaController.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    OtaController otaController;

    engine.rootContext()->setContextProperty("otaController", &otaController);
    otaController.initialize();


    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed, &app, []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);
    engine.loadFromModule("qnxOta", "Main");

    return app.exec();
}
