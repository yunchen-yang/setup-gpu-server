#!/bin/bash
set -e

echo "Ensuring CUDA is available..."
if command -v nvcc &> /dev/null; then
    nvcc --version
else
    echo "Warning: nvcc command not found. CUDA might not be installed or configured in PATH."
    # We don't exit here because users may just use pre-built wheels without nvcc.
fi

echo "Setting up Python virtual environment..."
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi

echo "Activating virtual environment and installing dependencies..."
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo "Setting up Trellis and Trellis.2..."
mkdir -p models
cd models

if [ ! -d "TRELLIS" ]; then
    echo "Cloning TRELLIS (original)..."
    git clone --recurse-submodules https://github.com/microsoft/TRELLIS.git
    cd TRELLIS
    echo "Installing TRELLIS dependencies via setup.sh..."
    bash setup.sh --basic --xformers --flash-attn --diffoctreerast --vox2seq --spconv --kaolin --nvdiffrast
    cd ..
else
    echo "TRELLIS already cloned."
fi

if [ ! -d "TRELLIS.2" ]; then
    echo "Cloning TRELLIS.2..."
    git clone --recurse-submodules https://github.com/microsoft/TRELLIS.2.git
    cd TRELLIS.2
    echo "Installing TRELLIS.2 dependencies via setup.sh..."
    bash setup.sh --basic --flash-attn --cumesh --o-voxel --flexgemm --nvdiffrast --nvdiffrec
    cd ..
else
    echo "TRELLIS.2 already cloned."
fi
cd ..

echo "Setup complete. You can now start the API with 'make start'."

