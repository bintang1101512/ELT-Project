from google.cloud import bigquery
from datetime import timedelta
from config import PROJECT

client = bigquery.Client(project=PROJECT)

def get_last_date():

    query = f"""
            select max(updated_at) as last_date
            from `{PROJECT}.noovoleum_data_v2_staging.stg_transaction`
"""
    
    result = client.query(query).result()

    for row in result:
        if row.last_date:
            safe_time = row.last_date - timedelta(minutes=10)
            return safe_time.strftime("%Y-%m-%dT%H:%M:%S")
        
        return "2026-01-01T00:00:00"
    