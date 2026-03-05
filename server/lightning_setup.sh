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
echo "=== Setting up TRELLIS.2 ==="
mkdir -p models
cd models

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

# --- Basic dependencies for TRELLIS.2 ---
echo "Installing TRELLIS.2 basic dependencies..."
pip install pillow imageio imageio-ffmpeg tqdm easydict opencv-python-headless \
    scipy ninja rembg onnxruntime trimesh open3d xatlas pyvista pymeshfix \
    igraph transformers==4.57.6
pip install git+https://github.com/EasternJournalist/utils3d.git@9a4eb15e4021b67b12c460c7057d642626897ec8
pip install kornia timm gradio tensorboard pandas lpips zstandard
sudo apt install -y libjpeg-dev 2>/dev/null || echo "Warning: Could not install libjpeg-dev. Skipping pillow-simd."
pip install pillow-simd 2>/dev/null || echo "Warning: pillow-simd install failed. Using regular pillow."

# --- Attention backend (GPU-dependent: flash-attn for Ampere+, xformers for older) ---
echo "Detecting GPU compute capability..."
GPU_CC=$(python -c "import torch; print(torch.cuda.get_device_capability()[0])" 2>/dev/null || echo "0")
echo "  GPU compute capability major version: ${GPU_CC}"

if [ "$GPU_CC" -ge 8 ]; then
    echo "  Ampere+ GPU detected (sm_8x+). Installing flash-attn..."
    pip install https://github.com/Dao-AILab/flash-attention/releases/download/v2.8.3/flash_attn-2.8.3+cu12torch2.8cxx11abiTRUE-cp312-cp312-linux_x86_64.whl \
        || echo "Warning: flash-attn install failed. Will fall back to xformers."
    # Also install xformers as a fallback (--no-deps to avoid upgrading torch)
    pip install xformers --no-deps 2>/dev/null || true
else
    echo "  Pre-Ampere GPU detected (sm_${GPU_CC}x). Installing xformers..."
    pip install xformers --no-deps || echo "Warning: xformers install failed."
fi

# --- nvdiffrast (needs --no-build-isolation) ---
echo "Installing nvdiffrast..."
if [ ! -d "/tmp/extensions/nvdiffrast" ]; then
    git clone https://github.com/NVlabs/nvdiffrast.git /tmp/extensions/nvdiffrast
fi
pip install /tmp/extensions/nvdiffrast --no-build-isolation || echo "Warning: nvdiffrast install failed."

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