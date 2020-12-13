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