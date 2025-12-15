cmake_minimum_required(VERSION 3.13)

project(ota_backend LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# --------------------------------------------------
# CommonAPI / SOME-IP
# --------------------------------------------------
set(CMAKE_PREFIX_PATH
    "/opt/commonapi/runtime"
    "/opt/commonapi/vsomeip"
)

find_package(CommonAPI REQUIRED CONFIG)
find_package(CommonAPI-SomeIP REQUIRED CONFIG)
find_package(vsomeip3 REQUIRED)
find_package(Threads REQUIRED)

# --------------------------------------------------
# Generated sources (EXPLICIT)
# --------------------------------------------------

# SOME/IP implementation cpp files (ONLY these compile)
set(SOMEIP_GEN_SRC
    src-gen/someip/v0/filetransfer/example/FileTransferSomeIPDeployment.cpp
    src-gen/someip/v0/filetransfer/example/FileTransferSomeIPProxy.cpp
    src-gen/someip/v0/filetransfer/example/FileTransferSomeIPStubAdapter.cpp
)

# Core headers (headers-only, but we list them for Qt Creator)
set(CORE_GEN_HDR
    src-gen/core/v0/filetransfer/example/FileTransfer.hpp
    src-gen/core/v0/filetransfer/example/FileTransferProxy.hpp
    src-gen/core/v0/filetransfer/example/FileTransferProxyBase.hpp
    src-gen/core/v0/filetransfer/example/FileTransferStub.hpp
    src-gen/core/v0/filetransfer/example/FileTransferStubDefault.hpp
)

# --------------------------------------------------
# Backend library
# --------------------------------------------------
add_library(ota_backend STATIC
    src/OtaBackend.cpp
    ${SOMEIP_GEN_SRC}
    ${CORE_GEN_HDR}   # headers only
)

# --------------------------------------------------
# Include paths
# --------------------------------------------------
target_include_directories(ota_backend
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/src
        ${CMAKE_CURRENT_SOURCE_DIR}/src-gen
        ${CMAKE_CURRENT_SOURCE_DIR}/src-gen/core
        ${CMAKE_CURRENT_SOURCE_DIR}/src-gen/someip
        ${COMMONAPI_INCLUDE_DIRS}
        ${COMMONAPI_SOMEIP_INCLUDE_DIRS}
        ${VSOMEIP_INCLUDE_DIRS}
)

# --------------------------------------------------
# Link libraries
# --------------------------------------------------
target_link_libraries(ota_backend
    PUBLIC
        CommonAPI
        CommonAPI-SomeIP
        vsomeip3
        Threads::Threads
)
