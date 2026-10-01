import requests
import json
import time
from datetime import datetime, UTC
from config import API_URL, ROWS, MAX_RETRY
from big_query_utils import get_last_date
import logging

logging.basicConfig(level=logging.INFO)

def extract(token):

    skip = 0
    retry_count = 0
    ingested = 0
    start_date = get_last_date()
    end_date = datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%S")

    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/json"
    }

    logging.info(f"Start Extract From {start_date} until {end_date}")

    while True:

        params ={
            "rows" : ROWS,
            "skip" : skip,
            "startDate" : start_date,
            "endDate" : end_date
        }

        try:
            resp = requests.get(
                url=API_URL,
                headers=headers,
                params=params,
                timeout=(3,60)
            )

            if resp.status_code == 403:
                logging.warning("Token Expired")
                raise Exception("403 Forbidden")
            
            if resp.status_code != 200:
                retry_count += 1
                logging.info(f"req gagal status : {resp.status_code}, retry : {retry_count}")
                if retry_count >= MAX_RETRY:
                    logging.info(f"Req gagal retry limit {retry_count}")
                    break
                time.sleep(3)

                continue

            data = resp.json()
            result = data.get("result", [])

            if not result:
                logging.info("Tidak ada Data Lagi")
                break

            for row in result:
                extra = row.get("extraData")

                if extra and "image" in extra:
                    extra.pop("image", None)

                yield row
                ingested += 1

                if ingested % 100 == 0:
                    logging.info(f"ingested: {ingested} rows")

            skip += ROWS
            retry_count = 0

            time.sleep(1)

        except Exception as e:
            logging.warning(e)
            retry_count += 1
            if retry_count >= MAX_RETRY:
                break
            time.sleep(3)