#!/bin/bash
set -e

echo "Installing dependencies into Lightning default environment..."
pip install --upgrade pip
pip install -r requirements.txt

echo "Setting up Trellis and Trellis.2..."
mkdir -p models
cd models

if [ ! -d "TRELLIS" ]; then
    echo "Cloning TRELLIS..."
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
    echo "Pre-installing libjpeg-dev (needed by pillow-simd in TRELLIS.2)..."
    sudo apt install -y libjpeg-dev 2>/dev/null || echo "Warning: Could not install libjpeg-dev via sudo. pillow-simd may fail; regular pillow will be used as fallback."
    echo "Installing TRELLIS.2 dependencies via setup.sh..."
    bash setup.sh --basic --flash-attn --cumesh --o-voxel --flexgemm --nvdiffrast --nvdiffrec
    cd ..
else
    echo "TRELLIS.2 already cloned."
fi

cd ..
echo "Setup complete."