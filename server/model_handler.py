import logging
import sys
import os
import base64
import io
import tempfile
from typing import Dict, Any

logger = logging.getLogger(__name__)

class ModelHandler:
    """
    Generic wrapper for handling different model inferences.
    This can be extended to dynamically load specialized plugins
    for Ollama, Trellis 2, etc.
    """
    def __init__(self):
        # A dictionary to hold loaded models or model interfaces.
        self.models = {}
        logger.info("Initialized ModelHandler")

    def load_model(self, model_id: str, parameters: Dict[str, Any]):
        """
        Dynamically load a model if not already loaded.
        """
        if model_id not in self.models:
            logger.info(f"Loading model: {model_id} with parameters: {parameters}")
            
            # Application-specific model initialization
            if model_id == "trellis2":
                 # Ensure the repository is in the Python path
                trellis2_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "models", "TRELLIS.2"))
                if trellis2_path not in sys.path:
                    sys.path.append(trellis2_path)
                
                try:
                    os.environ.setdefault('OPENCV_IO_ENABLE_OPENEXR', '1')
                    os.environ.setdefault('PYTORCH_CUDA_ALLOC_CONF', 'expandable_segments:True')
                    from trellis2.pipelines import Trellis2ImageTo3DPipeline
                    pipeline = Trellis2ImageTo3DPipeline.from_pretrained("microsoft/TRELLIS.2-4B")
                    if parameters.get("use_gpu", True):
                        pipeline.cuda()
                    self.models[model_id] = pipeline
                    logger.info("Trellis 2 model loaded successfully.")
                except ImportError as e:
                    logger.error(f"Failed to import Trellis 2 pipeline: {e}")
                    raise RuntimeError(f"Trellis 2 dependencies are missing: {e}")

            else:
                self.models[model_id] = "MockModelInstance"
                logger.info(f"Mock Model {model_id} loaded successfully.")
        
        return self.models[model_id]

    def infer(self, model_id: str, task_type: str, inputs: Dict[str, Any], parameters: Dict[str, Any]):
        """
        Run inference using the specified model.
        """
        try:
            # Ensure model is ready
            self.load_model(model_id, parameters)
            
            logger.info(f"Running inference on model {model_id} for task type {task_type}")
            
            # Application-specific logic routing based on task type.
            if task_type == "text_generation":
                return self._mock_text_generation(inputs, parameters)
            elif task_type == "image_generation":
                return self._mock_image_generation(inputs, parameters)
            elif task_type == "3d_generation":
                if model_id == "trellis2":
                    return self._trellis2_inference(inputs, parameters)
                else:
                    return self._mock_3d_generation(inputs, parameters)
            else:
                return {"status": "success", "echo": inputs, "message": "Generic inference executed"}
                
        except Exception as e:
            logger.error(f"Inference failed for {model_id}: {str(e)}")
            raise e

    def _mock_text_generation(self, inputs: Dict[str, Any], parameters: Dict[str, Any]):
        prompt = inputs.get("prompt", "")
        return {"generated_text": f"Mock response for prompt: {prompt}"}
        
    def _mock_image_generation(self, inputs: Dict[str, Any], parameters: Dict[str, Any]):
        return {"image_data": "base64_encoded_mock_image"}

    def _mock_3d_generation(self, inputs: Dict[str, Any], parameters: Dict[str, Any]):
        return {"mesh_data": "base64_encoded_gltf_mock_data"}

    def _decode_image(self, image_input: str) -> "Image.Image":
        """Decode a base64-encoded image string into a PIL Image."""
        from PIL import Image as PILImage
        img_bytes = base64.b64decode(image_input)
        return PILImage.open(io.BytesIO(img_bytes))

    def _trellis2_inference(self, inputs: Dict[str, Any], parameters: Dict[str, Any]):
        pipeline = self.models["trellis2"]
        image_input = inputs.get("image")
        if not image_input:
            raise ValueError("Trellis 2 inference requires an 'image' input.")

        image = self._decode_image(image_input)

        # Run the pipeline (see: TRELLIS.2/example.py)
        meshes = pipeline.run(image)
        mesh = meshes[0]
        mesh.simplify(parameters.get("max_triangles", 16777216))  # nvdiffrast limit

        # Export to GLB via o_voxel and serialize as base64
        import o_voxel
        glb = o_voxel.postprocess.to_glb(
            vertices=mesh.vertices,
            faces=mesh.faces,
            attr_volume=mesh.attrs,
            coords=mesh.coords,
            attr_layout=mesh.layout,
            voxel_size=mesh.voxel_size,
            aabb=[[-0.5, -0.5, -0.5], [0.5, 0.5, 0.5]],
            decimation_target=parameters.get("decimation_target", 1000000),
            texture_size=parameters.get("texture_size", 4096),
            remesh=parameters.get("remesh", True),
            remesh_band=parameters.get("remesh_band", 1),
            remesh_project=parameters.get("remesh_project", 0),
            verbose=True,
        )
        with tempfile.NamedTemporaryFile(suffix=".glb", delete=False) as tmp:
            glb.export(tmp.name, extension_webp=True)
            tmp.seek(0)
            glb_bytes = open(tmp.name, "rb").read()
        os.unlink(tmp.name)

        return {"glb_base64": base64.b64encode(glb_bytes).decode("utf-8")}
