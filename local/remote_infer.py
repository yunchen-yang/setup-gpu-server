import os
import requests
import functools
import logging
from typing import Any, Callable

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

# The default local port configured for port forwarding
DEFAULT_LOCAL_PORT = int(os.environ.get("LOCAL_API_PORT", 8000))

def remote_infer(model_id: str, task_type: str = "generic", port: int = DEFAULT_LOCAL_PORT) -> Callable:
    """
    A decorator that intercepts local function calls, serializes inputs, and routes
    them to the remote GPU server over an established SSH port-forwarding tunnel.
    
    Args:
        model_id (str): The identifier of the model to use on the server.
        task_type (str, optional): The type of task (e.g., 'text_generation', 'image_generation'). Defaults to "generic".
        port (int, optional): The local port forwarded to the remote API. Defaults to 8000.
    """
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs) -> Any:
            url = f"http://127.0.0.1:{port}/infer"
            
            # Serialize generic arguments. For more complex types like base64 images, 
            # you would convert them before calling the decorated function, or add logic here.
            inputs = kwargs.copy()
            if args:
                inputs["_args"] = args
                
            payload = {
                "model_id": model_id,
                "task_type": task_type,
                "inputs": inputs,
                "parameters": {}
            }
            
            logger.info(f"Routing call for '{func.__name__}' -> {url} (model: {model_id})")
            try:
                # Add a timeout to fail fast if the tunnel or server is unresponsive
                response = requests.post(url, json=payload, timeout=600)
                response.raise_for_status()
            except requests.exceptions.ConnectionError:
                logger.error(f"Connection failed. Is the SSH tunnel active on port {port}? Did you run ssh_connect.bat?")
                raise RuntimeError(f"Failed to connect to local port {port}.")
            except requests.exceptions.Timeout:
                logger.error("Request to remote server timed out.")
                raise RuntimeError(f"Request timed out on port {port}.")
            except requests.exceptions.HTTPError as e:
                logger.error(f"HTTP Error: {e.response.text}")
                raise RuntimeError(f"HTTP Error from remote server: {str(e)}")
                
            data = response.json()
            if data.get("status") == "error":
                error_msg = data.get("error_message", "Unknown error on server")
                logger.error(f"Server-side error: {error_msg}")
                raise RuntimeError(f"Remote exception: {error_msg}")
                
            # If successful, deserialize and return the exact expected payload
            return data.get("result")
            
        return wrapper
    return decorator
