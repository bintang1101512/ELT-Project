import os

API_URL = os.getenv("API_PICKUP_API_URL", "https://api.example.com/getAllPickups")
ROWS = 50
SKIP = 0
PROJECT = os.getenv("GCP_PROJECT_ID", "your-gcp-project")
DATASET = os.getenv("BQ_DATASET", "your_dataset")
TABLE = "raw_api_pickup"
TABLE_REF = f"{PROJECT}.{DATASET}.{TABLE}"
MAX_RETRY = 5
BATCH = 500