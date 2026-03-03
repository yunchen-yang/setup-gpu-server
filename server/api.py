import os
from dotenv import load_dotenv
load_dotenv()  # loads .env in the server/ directory (e.g. HF_TOKEN)
import logging
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Dict, Any, Optional

from model_handler import ModelHandler

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

app = FastAPI(title="GPU Server Inference API")
handler = ModelHandler()

class InferenceRequest(BaseModel):
    model_id: str
    task_type: str
    inputs: Dict[str, Any]
    parameters: Optional[Dict[str, Any]] = {}

class InferenceResponse(BaseModel):
    status: str
    result: Optional[Any] = None
    error_message: Optional[str] = None

@app.post("/infer", response_model=InferenceResponse)
async def infer_endpoint(request: InferenceRequest):
    logger.info(f"Received inference request for model: {request.model_id} (task: {request.task_type})")
    try:
        result = handler.infer(
            model_id=request.model_id,
            task_type=request.task_type,
            inputs=request.inputs,
            parameters=request.parameters
        )
        return InferenceResponse(status="success", result=result)
    except Exception as e:
        logger.error(f"Error processing inference request: {str(e)}")
        # Even if inference fails, returning a clean JSON is easier for the local wrapper to process
        return InferenceResponse(status="error", error_message=str(e))

@app.get("/health")
async def health_check():
    return {"status": "ok", "message": "GPU API is healthy"}

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("API_PORT", 8000))
    # Host must be 0.0.0.0 to allow access from the SSH tunnel logic
    uvicorn.run(app, host="0.0.0.0", port=port)
