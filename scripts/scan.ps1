# scan.ps1 - scans an image with Trivy
# Usage: .\scripts\scan.ps1 taskboard-api:0.1

param([string]$Image)

$scans = "$HOME\scans"
New-Item -ItemType Directory -Force $scans | Out-Null
docker save $Image -o "$scans\image.tar"

docker run --rm `
  -v "${scans}:/scan:ro" `
  -v trivy-cache:/root/.cache `
  aquasec/trivy:0.76.1 image `
  --input /scan/image.tar `
  --severity HIGH,CRITICAL `
  --ignore-unfixed `
  --quiet

Remove-Item "$scans\image.tar"
