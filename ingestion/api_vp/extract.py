import requests
import logging
import json
import time
from config import API_URL, MAX_RETRY

logging.basicConfig(level=logging.INFO)

def extract(token):
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/json"
    }

    for attempt in range(1, MAX_RETRY+1):
        try:
            logging.info(f"REQ API... Attempt = {attempt}")

            resp = requests.get(
                url=API_URL,
                headers=headers,
                timeout=(1,60)
            )

            if resp.status_code == 403:
                logging.warning(f"Token Expired")
                raise Exception("403 Forbidden")
            
            if resp.status_code != 200:
                logging.warning(f"REQ API gagal status_code: {resp.status_code}")

            data = resp.json().get("result", [])

            logging.info(f"TOTAL DATA: {len(data)} rows")

            for row in data:
                yield row


            return
        
        except Exception as e:
            logging.warning(f"API ERROR: {e}")
            if attempt == MAX_RETRY:
                raise
            time.sleep(3)

            