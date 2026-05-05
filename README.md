# ELT Pipeline — Multi-Source API to BigQuery

Production ELT pipeline ingesting data from multiple REST APIs into BigQuery, transformed with dbt, and deployed on GCP.

---

## Architecture

```
REST APIs (4 sources)
    │  incremental extract · pagination · Pydantic validation
    ▼
BigQuery Raw Layer
    │  dbt build (staging → intermediate → gold)
    │  dbt snapshot → SCD Type 2 (api_box)
    ▼
BigQuery Gold Layer (Star Schema)
    │
    ▼
Looker Studio · Power BI
```

**Orchestration:** Cloud Scheduler → Cloud Run (every 5 min) · Docker image stored in Artifact Registry

---

## Tech Stack

`Python` `dbt Core` `Google BigQuery` `Docker` `Cloud Run` `Cloud Scheduler` `Artifact Registry` 

---

## Highlights

- **Incremental load** — watermark-based, only fetch new/updated records
- **Paginated extract** — memory-efficient using Python generator (`yield`)
- **SCD Type 2** — full history tracking on `api_box` via dbt snapshot
- **Multi-layer DWH** — Raw → Staging → Gold with star schema
- **Data quality** — dbt tests for uniqueness, not_null, referential integrity

---

## Project Structure

```
├── pipeline.py          # Orchestrator — runs ingestion + dbt per source
├── ingestion/           # Extract & load scripts per API source
│   ├── api_box/
│   ├── api_transaction/
│   ├── api_vp/
│   └── api_pickup/
├── transform/           # dbt project (models, snapshots, tests)
└── logs/
```

---

## Usage

```bash
# Run full pipeline for a source
python pipeline.py api_box

# Available sources: api_box, api_transaction, api_vp, api_pickup
```

---

**Risky Bintang Munggaran** · [LinkedIn](https://linkedin.com/in/riskybintang1996) · [GitHub](https://github.com/bintang1101512)
