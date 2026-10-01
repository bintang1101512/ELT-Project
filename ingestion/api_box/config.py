import os

API_URL = os.getenv("API_BOX_API_URL", "https://api.example.com/getBoxes")
PROJECT = os.getenv("GCP_PROJECT_ID", "your-gcp-project")
DATASET = os.getenv("BQ_DATASET", "your_dataset")
TABLE = "raw_api_box"

TABLE_REF = f"{PROJECT}.{DATASET}.{TABLE}"
MAX_RETRY = 5