#!/bin/bash
set -e

echo "Installing dependencies into Lightning default environment..."
pip install --upgrade pip
pip install -r requirements.txt

echo "Setting up Trellis and Trellis.2..."
mkdir -p models
cd models

if [ ! -d "TRELLIS" ]; then
    git clone --recurse-submodules https://github.com/microsoft/TRELLIS.git
    cd TRELLIS
    pip install -r requirements-torch.txt
    pip install -r requirements-other.txt
    cd ..
fi

if [ ! -d "TRELLIS.2" ]; then
    git clone --recurse-submodules https://github.com/microsoft/TRELLIS.2.git
    cd TRELLIS.2
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
    fi
    cd ..
fi

cd ..
echo "Setup complete."