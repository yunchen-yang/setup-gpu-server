import sys
import os
import psutil

def check_cuda():
    print("--- Checking CUDA and PyTorch ---")
    try:
        import torch
        print(f"PyTorch Version: {torch.__version__}")
        if torch.cuda.is_available():
            print("CUDA is available.")
            print(f"CUDA Device Count: {torch.cuda.device_count()}")
            for i in range(torch.cuda.device_count()):
                props = torch.cuda.get_device_properties(i)
                vram_gb = props.total_memory / (1024**3)
                print(f"Device {i}: {props.name} - VRAM: {vram_gb:.2f} GB")
                if vram_gb < 16.0:
                    print(f"WARNING: Device {i} has less than 16GB VRAM. Trellis may OOM.")
                if vram_gb < 24.0:
                    print(f"WARNING: Device {i} has less than 24GB VRAM. Trellis.2 may OOM.")
        else:
            print("ERROR: CUDA is NOT available.")
            sys.exit(1)
    except ImportError:
        print("ERROR: PyTorch is not installed. Please check setup.sh.")
        sys.exit(1)

def check_system_ram():
    print("\n--- Checking System RAM ---")
    ram_gb = psutil.virtual_memory().total / (1024**3)
    print(f"Total System RAM: {ram_gb:.2f} GB")
    if ram_gb < 32.0:
         print("WARNING: System RAM is less than 32GB. Model loading may struggle.")

def check_trellis_imports():
    print("\n--- Checking Trellis Repositories ---")
    models_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "models"))
    
    trellis_path = os.path.join(models_dir, "TRELLIS")
    if os.path.exists(trellis_path):
        print("TRELLIS repository found.")
        sys.path.append(trellis_path)
        try:
            from trellis.pipelines import TrellisImageTo3DPipeline
            print("TRELLIS pipeline import successful.")
        except ImportError as e:
            print(f"ERROR: Failed to import TRELLIS pipeline. Missing dependencies? Details: {e}")
    else:
        print("ERROR: TRELLIS repository not found.")

    trellis2_path = os.path.join(models_dir, "TRELLIS.2")
    if os.path.exists(trellis2_path):
        print("TRELLIS.2 repository found.")
        sys.path.append(trellis2_path)
        try:
            from trellis2.pipelines import Trellis2ImageTo3DPipeline
            print("TRELLIS.2 pipeline import successful (Note: This is a hypothetical import test).")
        except ImportError as e:
            print(f"WARNING: Failed to import TRELLIS.2 pipeline. Check actual module structure. Details: {e}")
    else:
        print("ERROR: TRELLIS.2 repository not found.")

if __name__ == "__main__":
    check_cuda()
    check_system_ram()
    check_trellis_imports()
    print("\nSetup QA Complete.")
