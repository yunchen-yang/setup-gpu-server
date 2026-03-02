import sys
import logging
from model_handler import ModelHandler

logging.basicConfig(level=logging.INFO)

def run_qa():
    handler = ModelHandler()
    
    # QA 1: Load Trellis
    print("\n--- Attempting to load Trellis ---")
    try:
        handler.load_model("trellis", {"use_gpu": True})
        print("SUCCESS: Trellis model loaded.")
    except Exception as e:
        print(f"FAILURE: Could not load Trellis model. Error: {e}")

    # QA 2: Mock Inference Trellis
    print("\n--- Attempting dummy inference on Trellis ---")
    try:
        # NOTE: Real image path would be needed. Passing dummy data.
        handler.infer("trellis", "3d_generation", {"image": "dummy_image_data"}, {"use_gpu": True})
    except ValueError as ve:
        print(f"EXPECTED FAILURE (Missing real image): {ve}")
    except Exception as e:
        print(f"UNEXPECTED FAILURE during Trellis inference: {e}")

    # QA 3: Load Trellis.2
    print("\n--- Attempting to load Trellis.2 ---")
    try:
        handler.load_model("trellis2", {"use_gpu": True})
        print("SUCCESS: Trellis.2 model loaded.")
    except Exception as e:
        print(f"FAILURE: Could not load Trellis.2 model. Error: {e}")

if __name__ == "__main__":
    run_qa()
