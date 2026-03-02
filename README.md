# Setup GPU Server

A generic, reusable template repository to streamline GPU server environment configuration (CUDA, Python, SSH) and establish a seamless local-to-remote model inference pipeline.

This repository natively supports Linux (Ubuntu) on the server side and Windows on the local client side.

## Directory Structure

- `server/`: Deployed to your remote GPU instance. Includes the FastAPI server and model handler.
- `local/`: Used on your local Windows machine. Includes the SSH tunneling script and python decorator.

## Usage Guide

### 1. Server-Side Setup

There are two ways to deploy and test the server code:

#### **Option A: Automated Deployment (Recommended for updates)**
From your local Windows machine, run the PowerShell script to automatically copy the `server/` directory and run the initialization and tests over SSH:
```powershell
.\local\deploy_and_test.ps1 -Username your_user -ServerAddress your_ip
```

#### **Option B: Manual SSH Deployment (Recommended for first-time installation)**
Because installing PyTorch and compiling TRELLIS dependencies can take time and sometimes encounter OS-level issues (like missing gcc), it is often better to run the setup interactively so you can see the compiler logs:

1. Copy the `server/` directory to your remote Linux machine (via `scp` or `git pull`).
2. SSH into your remote GPU server and navigate to the `server/` directory:
```bash
cd server/
make setup
```

#### **Run Quality Assurance Tests**
Once setup is complete (either manually or via the script), verify the installation by running the QA scripts on the server:

```bash
# Verifies PyTorch, CUDA (requires 16GB+ VRAM), and Trellis imports
.venv/bin/python qa_setup.py

# Verifies model instantiation (catches Out-Of-Memory errors)
.venv/bin/python qa_inference.py
```

#### **Start the Server**
Once QA passes, start the inference API on port `8000`:
```bash
make start
```
*Note: You may customize the port by setting `API_PORT` before running `make start`.*

### 2. Local Port Forwarding (Windows)

On your local Windows machine, open a command prompt or PowerShell, navigate to the `local/` directory, and run the SSH tunnel script:

```cmd
cd local\
ssh_connect.bat user@your_remote_server_ip
```
Leave this window open. It binds your local port `8000` to the remote server's port `8000` via SSH.

### 3. Local Python Integration

In your local Python project, install the required dependencies:

```cmd
pip install -r local/requirements.txt
```

You can now use the `@remote_infer` decorator to execute computationally heavy functions on the GPU server securely:

```python
from local.remote_infer import remote_infer

# By applying this decorator, calling create_image will transparently execute on the remote API
@remote_infer(model_id="trellis2", task_type="image_generation")
def create_image(prompt: str):
    pass

# When you call this, it is routed over the SSH tunnel
result = create_image(prompt="A beautiful sunset")
print(result)
```

## Adding Custom Models

The API is designed to be easily extensible. To integrate a new model (e.g., Ollama or Trellis) or a custom pipeline:

1. **Load the Model Initialization:** Open `server/model_handler.py` and modify the `load_model` method. Add the initialization logic for your model (e.g., loading model weights into GPU memory) and store it in `self.models[model_id]`.
2. **Add Task Routing:** In the `infer` method within the same file, add an `elif` statement to route your specific `task_type` to a new custom method.
3. **Implement Inference Logic:** Create a new method (similar to `_mock_text_generation` or `_mock_image_generation`) that accesses the pre-loaded model, runs inference using the provided `inputs`, and returns the results.
4. **Invoke from Local:** On your local machine, decorate your wrapper function with `@remote_infer` using the `model_id` and `task_type` you established in the server script.

Example of extending `infer()`:
```python
elif task_type == "my_custom_task":
    return self._my_custom_inference_method(inputs, parameters)
```
