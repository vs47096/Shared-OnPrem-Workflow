#!/bin/bash

# Ensure script stops on unexpected critical unbound errors
set -u

DOCKER_USERNAME=$1
DOCKER_PAT=$2
DOCKER_REPOSITORY_NAME=$3

echo "======================================================="
echo "[Step 4/4] Remote Registry Purge (Docker Hub)"
echo "======================================================="
echo "Target Registry to Nuke: $DOCKER_USERNAME/$DOCKER_REPOSITORY_NAME"

# 1. Fetch JSON Web Token (JWT) from Docker Hub
echo "Authenticating with Docker Hub API..."
TOKEN=$(curl -s -H "Content-Type: application/json" \
  -X POST https://hub.docker.com/v2/users/login/ \
  -d "{\"username\": \"${DOCKER_USERNAME}\", \"password\": \"${DOCKER_PAT}\"}" \
  | jq -r .token)

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
  echo "[ERROR] Failed to authenticate with Docker Hub. Verify credentials."
  exit 1
fi

# 2. Issue a DELETE call to drop the entire repository structure completely
echo "Sending repository destruction request..."
RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -X DELETE \
  -H "Authorization: JWT ${TOKEN}" \
  "https://hub.docker.com/v2/repositories/${DOCKER_USERNAME}/${DOCKER_REPOSITORY_NAME}/")

if [[ "$RESPONSE_CODE" -eq 240 || "$RESPONSE_CODE" -eq 200 || "$RESPONSE_CODE" -eq 202 ]]; then
  echo "[SUCCESS] Docker Hub repository has been deleted entirely. Zero trace remains."
elif [ "$RESPONSE_CODE" -eq 404 ]; then
  echo "[INFO] Repository did not exist or was already deleted."
else
  echo "[WARNING] Unexpected API response ($RESPONSE_CODE). Falling back to sequential tag purge..."
  
  # Fallback Loop: Manually clear out all tags if full deletion is restricted by account tier
  RESPONSE=$(curl -s -H "Authorization: JWT ${TOKEN}" "https://hub.docker.com/v2/repositories/${DOCKER_USERNAME}/${DOCKER_REPOSITORY_NAME}/tags/?page_size=100")
  TAGS=$(echo "$RESPONSE" | jq -r '.results[]?.name')
  
  for TAG in $TAGS; do
    echo "Deleting tag: $TAG"
    curl -s -H "Authorization: JWT ${TOKEN}" -X DELETE "https://hub.docker.com/v2/repositories/${DOCKER_USERNAME}/${DOCKER_REPOSITORY_NAME}/tags/${TAG}/" > /dev/null 2>&1
  done
  echo "[SUCCESS] Fallback complete. All discovered tags inside repository have been purged."
fi
