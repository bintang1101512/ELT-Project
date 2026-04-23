import sys
import subprocess
import logging

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger(__name__)


VALID_SOURCES = {"api_box", "api_transaction", "api_vp", "api_pickup"}


SOURCES_WITH_SNAPSHOT = {"api_box"}


def run_step(name, command, cwd=None):
    logger.info(f"START {name}")
    try:
        subprocess.run(command, cwd=cwd, check=True)
        logger.info(f"END   {name}")
    except subprocess.CalledProcessError as e:
        logger.error(f"FAILED {name} — return code {e.returncode}")
        raise


def run_ingestion(source):
    run_step(
        f"ingestion_{source}",
        ["python", "main.py"],
        cwd=f"ingestion/{source}",
    )


def run_dbt(source):
    select = f"path:models/{source}"
    if source in SOURCES_WITH_SNAPSHOT:
        select += f" path:snapshots/{source}"

    run_step(
        f"dbt_{source}",
        ["dbt", "build", "--select", select],
        cwd="transform",
    )


def run_pipeline(source):
    logger.info(f"========== PIPELINE {source.upper()} START ==========")
    run_ingestion(source)
    run_dbt(source)
    logger.info(f"========== PIPELINE {source.upper()} DONE  ==========")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        logger.error("Usage: python pipeline.py <source>")
        logger.error(f"Valid sources: {', '.join(sorted(VALID_SOURCES))}")
        sys.exit(1)

    source = sys.argv[1]

    if source not in VALID_SOURCES:
        logger.error(f"Invalid source '{source}'. Valid sources: {', '.join(sorted(VALID_SOURCES))}")
        sys.exit(1)

    run_pipeline(source)