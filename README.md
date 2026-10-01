# ELT Pipeline: Multi-Source REST API to BigQuery

Incremental ELT pipeline that loads four REST API sources into BigQuery and models them with dbt (staging and gold layers, plus an SCD Type 2 snapshot).

This is a sanitized version of a production pipeline. API endpoints, GCP project, and dataset names are read from environment variables, and no credentials are included.

## Architecture

```
REST APIs (4 sources)
    │  incremental extract (watermark), pagination, retry
    ▼
BigQuery raw layer         raw JSON payload + ingested_at
    │  dbt staging models  JSON parsing, typing, dedup, incremental merge
    │  dbt snapshot        SCD Type 2 on api_box
    ▼
BigQuery gold layer        transaction fact joined with box, user, and partner data
    ▼
Looker Studio, Power BI
```

`pipeline.py` runs ingestion and then `dbt build` for one source per run. In production it ran on Cloud Run, triggered by Cloud Scheduler.

## Lineage

![dbt lineage](docs/lineage.png)

Generated from the dbt manifest:

```bash
cd transform && dbt parse
python docs/make_lineage.py target/manifest.json docs/lineage.png
```

## Stack

Python, requests, google-cloud-bigquery, dbt Core (BigQuery adapter), Docker, Cloud Run, Cloud Scheduler, Artifact Registry

## Data tests

19 tests in `transform/models/schema.yml` and `transform/tests/`:

| Layer | Tests |
|---|---|
| Staging | `unique` and `not_null` on each key, `not_null` on `updated_at`, `relationships` from `stg_user` to `stg_transaction` (warn) |
| Gold | `unique` and `not_null` on `ta_id`, `relationships` to `stg_transaction`, `not_null` on `ta_start_time_wib`, `accepted_values` on `vp_status` |
| Singular | `assert_gold_duration_non_negative`, `assert_gold_no_fan_out` |

The definitions pass `dbt parse`. Run `dbt test` against your own BigQuery project to execute them.

## Setup

```bash
pip install -r requirements/requirements.txt
cp .env.example .env
```

| Variable | Purpose |
|---|---|
| `GCP_PROJECT_ID` | BigQuery project |
| `BQ_DATASET` | Base dataset name (staging and gold derive from it) |
| `API_TOKEN_TRX` | Bearer token for the source APIs |
| `API_*_API_URL` | Endpoint for each source |

BigQuery auth uses Application Default Credentials (`gcloud auth application-default login`), or the service account attached to Cloud Run.

## Usage

```bash
python pipeline.py api_box
```

Sources: `api_box`, `api_transaction`, `api_vp`, `api_pickup`.

## Not included yet

Dockerfile, CI, source freshness checks, an intermediate layer, and payload schema validation.

---

Risky Bintang Munggaran · [LinkedIn](https://linkedin.com/in/riskybintang1996) · [GitHub](https://github.com/bintang1101512)
