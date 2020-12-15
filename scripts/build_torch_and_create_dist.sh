#!/bin/bash

# TODO - Checkout setup_venv.sh in maester

# Create virtual environment
VENV_DIR=".venv"

python3 -m pip install --user virtualenv
python3 -m  virtualenv $VENV_DIR

# Activate virtual environment
source $VENV_DIR/bin/activate

# Install dependencies
pip install numpy ninja pyyaml mkl mkl-include setuptools cmake cffi typing

# Set CUDA arch list based on CUDA version - taken from https://github.com/pytorch/builder/blob/master/manywheel/build.sh
CUDA_VERSION=$(nvcc --version|grep release|cut -f5 -d" "|cut -f1 -d",")
echo "CUDA $CUDA_VERSION Detected"
TORCH_CUDA_ARCH_LIST="3.7;5.0;6.0;7.0"
case ${CUDA_VERSION} in
    11.1)
        TORCH_CUDA_ARCH_LIST="5.0;7.0;8.0;8.6"  # removing some to prevent bloated binary size
        EXTRA_CAFFE2_CMAKE_FLAGS+=("-DATEN_NO_TEST=ON")
        ;;
    11.0)
        TORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST};7.5;8.0"
        EXTRA_CAFFE2_CMAKE_FLAGS+=("-DATEN_NO_TEST=ON")
        ;;
    10.*)
        TORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST};7.5"
        EXTRA_CAFFE2_CMAKE_FLAGS+=("-DATEN_NO_TEST=ON")
        ;;
    9.*)
        TORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST}"
        ;;
    *)
        echo "unknown cuda version $CUDA_VERSION"
        exit 1
        ;;
esac

export TORCH_CUDA_ARCH_LIST=${TORCH_CUDA_ARCH_LIST}
echo "Compiling torch for the following CUDA compute capability ${TORCH_CUDA_ARCH_LIST}"

# Not compiling for all cuda architectures will result in following issue
# https://github.com/pytorch/pytorch/issues/31285
# https://developer.nvidia.com/cuda-gpus

# Build torch
python setup.py install

# Create whl
python setup.py sdist bdist_wheel

# Copy libtorch into temporary directory and compress
mkdir libtorch
cp -r torch/lib torch/share torch/include libtorch
tar -czvf x86-libtorch1.4.0-cuda10.0.7z libtorch

# Delete temporary directory
rm -rf libtorch

# TODO - take output dir as argument
mkdir luminar_torch_x86_dist

# Copy files in a single directory to make it easy to locate
cp -r dist luminar_torch_x86_dist
mv x86-libtorch1.4.0-cuda10.0.7z luminar_torch_x86_dist