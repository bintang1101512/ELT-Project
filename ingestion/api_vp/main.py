import os
import logging
from dotenv import load_dotenv
from extract import extract
from load import run_elt

load_dotenv()

logging.basicConfig(level=logging.INFO)

def main():

    token = os.getenv("API_TOKEN_TRX")

    if not token:
        raise ValueError("API_TOKEN_TRX tidak ditemukan!!!")
    
    try:
        total = run_elt(token, extract)
        logging.info(f"Ingest Berhasil TOTAL DATA: {total} rows")

    except Exception as e:
        logging.error(e)

if __name__ == "__main__":
    main()