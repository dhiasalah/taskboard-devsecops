#!/bin/bash
# scan.sh — scans an image with Trivy
# Usage: ./scripts/scan.sh taskboard-api:0.1

set -e

mkdir -p ~/scans
docker save "$1" -o ~/scans/image.tar

docker run --rm \
  -v ~/scans:/scan:ro \
  -v trivy-cache:/root/.cache \
  aquasec/trivy:0.76.1 image \
  --input /scan/image.tar \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --quiet

rm ~/scans/image.tar

