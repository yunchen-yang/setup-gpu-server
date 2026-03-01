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

echo "Setup complete. You can now start the API with 'make start'."
