import os
import logging
from dotenv import load_dotenv
from extract import extract
from load import run_elt

load_dotenv()

logging.basicConfig(level=logging.INFO)

def main():

    try:
        total = run_elt(extract)
        logging.info(f"Success {total} rows")
    
    except Exception as e:
        logging.error(e)

if __name__ == "__main__":
    main()