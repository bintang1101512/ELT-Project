import requests
import logging
import json
import time
from config import API_URL, MAX_RETRY

logging.basicConfig(level=logging.INFO)

def extract(token):
    headers = {
        "Authorization" : f"Bearer {token}",
        "Accept" : "application/json" 
    }

    for attemp in range(1, MAX_RETRY+1):
        try:
            logging.info(f"req API... attemp = {attemp}")

            resp = requests.get(
                url=API_URL,
                headers=headers,
                timeout=(1,60)
            )

            if resp.status_code == 403:
                logging.warning("Token Expired")
                raise Exception("403 Forbidden")
            
            if resp.status_code != 200:
                logging.warning(f"Req Gagal: {resp.status_code}")
                

            data = resp.json()

            logging.info(f"TOTAL DATA: {len(data)} ROWS")

            for row in data:
                yield row

            return
        
        except Exception as e:
            logging.warning(f"api ERROR: {e}")
            if attemp == MAX_RETRY:
                raise
            time.sleep(3)