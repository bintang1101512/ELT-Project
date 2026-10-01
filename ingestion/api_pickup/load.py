from google.cloud import bigquery
from datetime import datetime, UTC
from config import PROJECT, DATASET, TABLE_REF, BATCH

client = bigquery.Client(project=PROJECT)

def load_data(rows):

    job_config = bigquery.LoadJobConfig(
        write_disposition = "WRITE_APPEND"
    )

    client.load_table_from_json(rows, TABLE_REF, job_config=job_config).result()

def run_elt(extract):

    buffer = []
    total = 0

    for row in extract():

        buffer.append({
            "ingested_at" : datetime.now(UTC).isoformat(),
            "payload": row
        })

        total += 1

        if len(buffer) >= BATCH:
            load_data(buffer)
            buffer.clear()

    if buffer:
        load_data(buffer)

    return total

