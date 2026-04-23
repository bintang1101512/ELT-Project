from google.cloud import bigquery
from datetime import timedelta
from config import PROJECT, DATASET, TABLE

client = bigquery.Client(project=PROJECT)

def get_last_date():

    query = f"""
            select timestamp_sub(max(updated_at), INTERVAL 14 day) as last_date
            from `noovoleum-project.noovoleum_data_v2_staging.stg_pickup`
    """

    result = client.query(query).result()

    for row in result:
        if row.last_date:
            safe_time = row.last_date - timedelta(minutes=5)
            return safe_time.strftime("%Y-%m-%dT%H:%M:%S")
    
    return "2023-01-01T00:00:00"