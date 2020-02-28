#!/usr/bin/env bash

set -e

export TOP=$(pwd)

TOOLCHAIN_FILE=${TOP}/toolchain.cmake

# Prepare arm toolchain if needed
if [[ ${JOB_ARCHITECTURE} == arm ]]; then
    wget https://releases.linaro.org/components/toolchain/binaries/latest-7/arm-linux-gnueabihf/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf.tar.xz
    tar xvf gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf.tar.xz
    export PATH=${TOP}/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf/bin:${PATH}

    echo "SET(CMAKE_SYSTEM_NAME Linux)" >> ${TOOLCHAIN_FILE}
    echo "SET(CMAKE_SYSTEM_PROCESSOR arm)" >> ${TOOLCHAIN_FILE}
    echo "SET(CMAKE_C_COMPILER   arm-linux-gnueabihf-gcc)" >> ${TOOLCHAIN_FILE}
    echo "SET(CMAKE_CXX_COMPILER arm-linux-gnueabihf-g++)" >> ${TOOLCHAIN_FILE}
    echo "SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)" >> ${TOOLCHAIN_FILE}
    echo "SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)" >> ${TOOLCHAIN_FILE}
    echo "SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)" >> ${TOOLCHAIN_FILE}
fi

# Prepare headers
git clone https://github.com/KhronosGroup/OpenCL-Headers.git
cd OpenCL-Headers
ln -s CL OpenCL # For OSX builds
cd ..

# Get and build loader
git clone https://github.com/KhronosGroup/OpenCL-ICD-Loader.git
cd ${TOP}/OpenCL-ICD-Loader
mkdir build
cd build
cmake -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE} -DOPENCL_ICD_LOADER_HEADERS_DIR=${TOP}/OpenCL-Headers/ ..
make

# Get libclcxx
cd ${TOP}
git clone https://github.com/KhronosGroup/libclcxx.git

# Build CTS
ls -l
mkdir build
cd build
cmake -DCL_INCLUDE_DIR=${TOP}/OpenCL-Headers \
      -DCL_LIB_DIR=${TOP}/OpenCL-ICD-Loader/build \
      -DCL_LIBCLCXX_DIR=${TOP}/libclcxx \
      -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE} \
      -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=./bin \
      -DOPENCL_LIBRARIES="-lOpenCL -lpthread" \
      ..
make -j2

