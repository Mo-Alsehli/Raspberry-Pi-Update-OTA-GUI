cmake_minimum_required(VERSION 3.16)

project(qnxOta VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appqnxOta
    main.cpp
)

qt_add_qml_module(appqnxOta
    URI qnxOta
    VERSION 1.0
    QML_FILES
        Main.qml
        RESOURCES assets/download.png
        RESOURCES
        RESOURCES assets/refresh.png
        RESOURCES assets/blackberry.png assets/ethernet.png assets/server.png assets/shield.png
        RESOURCES assets/cpu.png assets/memory-card.png assets/temp.png
        RESOURCES assets/ram.png
        RESOURCES assets/log.png
        RESOURCES assets/info.png
        QML_FILES components/OnlineStatusIndicator.qml
        QML_FILES components/CardShadow.qml
        QML_FILES components/StatusTile.qml
        QML_FILES components/MetricRow.qml
        QML_FILES components/LogEntry.qml
        QML_FILES cards/CardIdle.qml
        QML_FILES cards/CardChecking.qml
        QML_FILES components/PrimaryButton.qml
        QML_FILES cards/CardUpToDate.qml
        RESOURCES assets/checkmark.png
        QML_FILES cards/CardUpdateAvailable.qml
        RESOURCES assets/download-update.png
        QML_FILES cards/CardRequestRefused.qml
        RESOURCES assets/error.png
        QML_FILES cards/CardDownloading.qml
        QML_FILES cards/CardDownloadFinished.qml
        RESOURCES assets/power.png
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appqnxOta PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appqnxOta
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appqnxOta
    PRIVATE Qt6::Quick
)

include(GNUInstallDirs)
install(TARGETS appqnxOta
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
