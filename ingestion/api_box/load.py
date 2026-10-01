from google.cloud import bigquery
from datetime import datetime, UTC
from config import PROJECT, DATASET, TABLE, TABLE_REF

client = bigquery.Client(project=PROJECT)

def load_data(buffer):

    job_config = bigquery.LoadJobConfig(
        write_disposition = "WRITE_APPEND"
    )

    client.load_table_from_json(
        buffer,
        TABLE_REF,
        job_config=job_config,
    ).result()

def run_elt(token, extract):

    buffer = []
    total = 0

    for row in extract(token):

        buffer.append({
            "payload" : row,
            "ingested_at" : datetime.now(UTC).isoformat()
        })

        total += 1

    if buffer:
        load_data(buffer)

    return total