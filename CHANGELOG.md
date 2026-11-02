# Changelog

## v0.1 — Containerized app

- Web page, Flask API and Postgres, each in its own container
- One command to run: `docker compose up -d`
- Non-root images, with Trivy scans
- The database has no door on the laptop, and only the API can reach it
- Images published on Docker Hub

