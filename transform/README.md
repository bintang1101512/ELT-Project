# dbt project

Models, snapshots, and BigQuery profile for the ELT pipeline. See the root README for the architecture.

```bash
cd transform
export GCP_PROJECT_ID=your-gcp-project
export BQ_DATASET=your_dataset
dbt build --select path:models/api_box path:snapshots/api_box
```

`profiles.yml` reads the project and dataset from environment variables and authenticates with OAuth (Application Default Credentials).
