cmake_minimum_required(VERSION 3.16)

project(qnxOta VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.8)

add_subdirectory(backend)

qt_add_executable(appqnxOta
    main.cpp
    OtaController.cpp
    OtaController.h
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
        SOURCES OtaController.cpp
        SOURCES OtaController.h
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

find_package(CommonAPI REQUIRED CONFIG)
find_package(CommonAPI-SomeIP REQUIRED CONFIG)
find_package(vsomeip3 REQUIRED)
find_package(Threads REQUIRED)


target_link_libraries(appqnxOta
    PRIVATE
        Qt6::Quick
        -Wl,--whole-archive ota_backend -Wl,--no-whole-archive # Very Important
        CommonAPI
        CommonAPI-SomeIP
        vsomeip3
        Threads::Threads
)

# Prevent dropping libs that are "only" needed for static init
target_link_options(appqnxOta PRIVATE "-Wl,--no-as-needed")

target_link_libraries(appqnxOta PRIVATE
    "-Wl,--whole-archive" CommonAPI-SomeIP "-Wl,--no-whole-archive"
)


include(GNUInstallDirs)
install(TARGETS appqnxOta
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
