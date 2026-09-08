from io import BytesIO
import os
from fastapi import FastAPI, File, UploadFile, HTTPException
from PIL import Image

app = FastAPI(title="AgriSense AI", version="0.1.0")

MODEL_ID = os.getenv("AGRISENSE_MODEL", "kimcomehome/plantvillage-vit-leaf-disease")
_classifier = None


def classifier():
    global _classifier
    if _classifier is None:
        from transformers import pipeline
        _classifier = pipeline("image-classification", model=MODEL_ID)
    return _classifier


@app.get("/health")
def health():
    return {"status": "ok", "model": MODEL_ID}


@app.post("/v1/disease/predict")
async def predict(file: UploadFile = File(...)):
    if file.content_type not in {"image/jpeg", "image/png", "image/webp"}:
        raise HTTPException(415, "Upload a JPEG, PNG, or WebP image.")
    data = await file.read()
    if len(data) > 10 * 1024 * 1024:
        raise HTTPException(413, "Image is larger than 10 MB.")
    try:
        image = Image.open(BytesIO(data)).convert("RGB")
        results = classifier()(image, top_k=5)
    except Exception as exc:
        raise HTTPException(500, "Inference failed.") from exc
    return {"model": MODEL_ID, "predictions": results}
