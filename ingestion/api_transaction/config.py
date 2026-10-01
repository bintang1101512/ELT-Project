import os

PROJECT = os.getenv("GCP_PROJECT_ID", "your-gcp-project")
DATASET = os.getenv("BQ_DATASET", "your_dataset")
TABLE = "raw_api"

TABLE_REF = f"{PROJECT}.{DATASET}.{TABLE}"
API_URL = os.getenv("API_TRANSACTION_API_URL", "https://api.example.com/getTransaction")

ROWS = 50
BATCH = 200
MAX_RETRY = 5