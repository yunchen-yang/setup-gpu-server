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

echo "Setting up Trellis.2..."
mkdir -p models
cd models

if [ ! -d "TRELLIS.2" ]; then
    echo "Cloning TRELLIS.2..."
    git clone --recurse-submodules https://github.com/microsoft/TRELLIS.2.git
    cd TRELLIS.2
    echo "Installing TRELLIS.2 dependencies via setup.sh..."
```bash
    sed -i 's/transformers/transformers==4.57.6/g' setup.sh
    bash setup.sh --basic --flash-attn --cumesh --o-voxel --flexgemm --nvdiffrast --nvdiffrec
```
    cd ..
else
    echo "TRELLIS.2 already cloned."
fi
cd ..

echo "Setup complete. You can now start the API with 'make start'."

