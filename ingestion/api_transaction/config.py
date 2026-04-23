PROJECT = "noovoleum-project"
DATASET = "noovoleum_data_v2"
TABLE = "raw_api"

TABLE_REF = f"{PROJECT}.{DATASET}.{TABLE}"
API_URL = "https://api.noovoleum.com/api/admin/engineer/getTransaction"

ROWS = 50
BATCH = 200
MAX_RETRY = 5