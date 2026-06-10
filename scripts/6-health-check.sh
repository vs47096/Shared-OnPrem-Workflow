#!/usr/bin/env bash
# Shared-OnPrem-Workflow/scripts/6-health-check.sh
set -e

PORT=$1
CONTAINER_NAME=$2
MAX_ATTEMPTS=12
ATTEMPT=1
SUCCESS=false

echo "======================================================="
echo "       Activating Application Health Monitor Layer     "
echo "======================================================="
echo "Targeting Endpoint: http://localhost:${PORT}/actuator/health"
echo "Monitoring Container: ${CONTAINER_NAME}"

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
  echo "Checking application status (Attempt ${ATTEMPT}/${MAX_ATTEMPTS})..."
  
  # Try contacting the application. If curl throws code 52/7, suppress it and output 000.
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT}/actuator/health || echo "000")
  
  # Clean white spaces
  HTTP_CODE=$(echo "$HTTP_CODE" | tr -d '[:space:]')
  echo "Application layer responded with status code: ${HTTP_CODE}"
  
  if [ "$HTTP_CODE" = "200" ]; then
    echo "[SUCCESS] Core services are healthy and responding with 200 OK!"
    SUCCESS=true
    break
  fi
  
  echo "Application not ready yet. Retrying in 5 seconds..."
  sleep 5
  ATTEMPT=$((ATTEMPT+1))
done

if [ "$SUCCESS" = "false" ]; then
  echo ""
  echo "[CRITICAL ERROR] Application failed to report healthy within 60 seconds."
  echo "=== Fetching Last 50 Lines of Active Container Logs ==="
  docker logs --tail 50 "${CONTAINER_NAME}"
  echo "======================================================="
  exit 1
fi
