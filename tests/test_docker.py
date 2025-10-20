import os
import subprocess
import time
from pathlib import Path

import requests


IMAGE_TAG = "open-deep-research:test"
CONTAINER_NAME = "open-deep-research-test"
PORT = 2024


def run(cmd: list[str]) -> None:
    subprocess.run(cmd, check=True)


def wait_for(url: str, timeout_seconds: int = 60) -> None:
    deadline = time.time() + timeout_seconds
    last_err: Exception | None = None
    while time.time() < deadline:
        try:
            resp = requests.get(url, timeout=5)
            if resp.status_code < 500:
                return
        except Exception as err:  # noqa: BLE001
            last_err = err
        time.sleep(2)
    raise TimeoutError(f"Timed out waiting for {url}. Last error: {last_err}")


def test_docker_container_smoke():
    project_root = Path(__file__).resolve().parents[1]

    # Ensure env file exists
    env_file = project_root / ".env"
    if not env_file.exists():
        template = project_root / "env.example"
        if not template.exists():
            raise FileNotFoundError("env.example missing; cannot create .env for test")
        env_file.write_text(template.read_text(), encoding="utf-8")

    # Build image
    run(["docker", "build", "-t", IMAGE_TAG, str(project_root)])

    # Stop/remove any leftover container
    subprocess.run(["docker", "rm", "-f", CONTAINER_NAME], check=False)

    # Run container
    run([
        "docker",
        "run",
        "--name",
        CONTAINER_NAME,
        "--env-file",
        str(env_file),
        "-p",
        f"{PORT}:{PORT}",
        IMAGE_TAG,
    ])

    try:
        wait_for(f"http://localhost:{PORT}/health", timeout_seconds=90)
        wait_for(f"http://localhost:{PORT}/docs", timeout_seconds=30)
    finally:
        subprocess.run(["docker", "rm", "-f", CONTAINER_NAME], check=False)
        subprocess.run(["docker", "rmi", IMAGE_TAG], check=False)


