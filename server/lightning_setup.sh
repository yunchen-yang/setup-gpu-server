#!/bin/bash
set -e

echo "=== Lightning AI Studio Setup ==="
echo "Installing into Lightning's default conda environment..."

# Show environment info
echo "Python: $(python --version)"
echo "PyTorch: $(python -c 'import torch; print(torch.__version__)')"
echo "CUDA: $(python -c 'import torch; print(torch.version.cuda)')"

# Install our project dependencies
pip install --upgrade pip
pip install -r requirements.txt

# -------------------------------------------------------
# Clone TRELLIS repos
# -------------------------------------------------------
echo ""
echo "=== Setting up TRELLIS and TRELLIS.2 ==="
mkdir -p models
cd models

if [ ! -d "TRELLIS" ]; then
    echo "Cloning TRELLIS..."
    git clone --recurse-submodules https://github.com/microsoft/TRELLIS.git
else
    echo "TRELLIS already cloned."
fi

if [ ! -d "TRELLIS.2" ]; then
    echo "Cloning TRELLIS.2..."
    git clone --recurse-submodules https://github.com/microsoft/TRELLIS.2.git
else
    echo "TRELLIS.2 already cloned."
fi

# -------------------------------------------------------
# Install dependencies manually (upstream setup.sh scripts
# don't support PyTorch 2.8 / CUDA 12.8 on Lightning)
# -------------------------------------------------------
echo ""
echo "=== Installing TRELLIS dependencies manually ==="

# --- Basic dependencies (from TRELLIS --basic) ---
echo "Installing basic dependencies..."
pip install pillow imageio imageio-ffmpeg tqdm easydict opencv-python-headless \
    scipy ninja rembg onnxruntime trimesh open3d xatlas pyvista pymeshfix \
    igraph transformers
pip install git+https://github.com/EasternJournalist/utils3d.git@9a4eb15e4021b67b12c460c7057d642626897ec8

# --- Additional basic deps from TRELLIS.2 --basic ---
echo "Installing TRELLIS.2 basic dependencies..."
pip install kornia timm gradio tensorboard pandas lpips zstandard
sudo apt install -y libjpeg-dev 2>/dev/null || echo "Warning: Could not install libjpeg-dev. Skipping pillow-simd."
pip install pillow-simd 2>/dev/null || echo "Warning: pillow-simd install failed. Using regular pillow."

# --- xformers ---
# Skipped: PyTorch 2.8 has built-in SDPA (Scaled Dot Product Attention)
# which serves as a drop-in replacement. No need for xformers.
echo "Skipping xformers (PyTorch 2.8+ has built-in SDPA attention)."

# --- flash-attn (prebuilt wheel — pip build fails with cross-device link error on Lightning) ---
echo "Installing flash-attn..."
pip install https://github.com/Dao-AILab/flash-attention/releases/download/v2.8.3/flash_attn-2.8.3+cu12torch2.8cxx11abiTRUE-cp312-cp312-linux_x86_64.whl \
    || echo "Warning: flash-attn install failed. SDPA will be used as fallback."

# --- nvdiffrast (needs --no-build-isolation) ---
echo "Installing nvdiffrast..."
if [ ! -d "/tmp/extensions/nvdiffrast" ]; then
    git clone https://github.com/NVlabs/nvdiffrast.git /tmp/extensions/nvdiffrast
fi
pip install /tmp/extensions/nvdiffrast --no-build-isolation || echo "Warning: nvdiffrast install failed."

# --- diffoctreerast (needs --no-build-isolation) ---
echo "Installing diffoctreerast..."
if [ ! -d "/tmp/extensions/diffoctreerast" ]; then
    git clone --recurse-submodules https://github.com/JeffreyXiang/diffoctreerast.git /tmp/extensions/diffoctreerast
fi
pip install /tmp/extensions/diffoctreerast --no-build-isolation || echo "Warning: diffoctreerast install failed."

# --- vox2seq (from TRELLIS repo's extensions/ dir) ---
echo "Installing vox2seq..."
if [ -d "TRELLIS/extensions/vox2seq" ]; then
    cp -r TRELLIS/extensions/vox2seq /tmp/extensions/vox2seq 2>/dev/null || true
    pip install /tmp/extensions/vox2seq --no-build-isolation || echo "Warning: vox2seq install failed."
else
    echo "Warning: TRELLIS/extensions/vox2seq not found. Skipping."
fi

# --- spconv ---
echo "Installing spconv..."
CUDA_MAJOR=$(python -c "import torch; print(torch.version.cuda.split('.')[0])")
pip install spconv-cu${CUDA_MAJOR}0 2>/dev/null \
    || pip install spconv 2>/dev/null \
    || echo "Warning: spconv install failed."

# --- kaolin ---
echo "Installing kaolin..."
pip install kaolin 2>/dev/null || echo "Warning: kaolin install failed (no prebuilt wheel for this PyTorch/CUDA version)."

# --- TRELLIS.2 specific extensions (need --no-build-isolation) ---
echo "Installing TRELLIS.2 extensions..."

# nvdiffrec
if [ ! -d "/tmp/extensions/nvdiffrec" ]; then
    git clone -b renderutils https://github.com/JeffreyXiang/nvdiffrec.git /tmp/extensions/nvdiffrec
fi
pip install /tmp/extensions/nvdiffrec --no-build-isolation || echo "Warning: nvdiffrec install failed."

# CuMesh
if [ ! -d "/tmp/extensions/CuMesh" ]; then
    git clone https://github.com/JeffreyXiang/CuMesh.git /tmp/extensions/CuMesh --recursive
fi
pip install /tmp/extensions/CuMesh --no-build-isolation || echo "Warning: CuMesh install failed."

# FlexGEMM
if [ ! -d "/tmp/extensions/FlexGEMM" ]; then
    git clone https://github.com/JeffreyXiang/FlexGEMM.git /tmp/extensions/FlexGEMM --recursive
fi
pip install /tmp/extensions/FlexGEMM --no-build-isolation || echo "Warning: FlexGEMM install failed."

# o-voxel (from TRELLIS.2 repo)
if [ -d "TRELLIS.2/o-voxel" ]; then
    cp -r TRELLIS.2/o-voxel /tmp/extensions/o-voxel 2>/dev/null || true
    pip install /tmp/extensions/o-voxel --no-build-isolation || echo "Warning: o-voxel install failed."
else
    echo "Warning: TRELLIS.2/o-voxel not found. Skipping."
fi

cd ..
echo ""
echo "=== Setup complete ==="
echo "You can now start the API with 'make lightning_start'."