#!/bin/bash

set -eu

DOCKER_USERNAME=$1
DOCKER_PAT=$2
DOCKER_REPOSITORY_NAME=$3

echo "======================================================="
echo "[Step 4/4] Docker Hub Tag Cleanup"
echo "======================================================="
echo "Repository: $DOCKER_USERNAME/$DOCKER_REPOSITORY_NAME"

echo "Authenticating with Docker Hub..."

TOKEN=$(curl -s \
  -H "Content-Type: application/json" \
  -X POST \
  https://hub.docker.com/v2/users/login/ \
  -d "{\"username\":\"${DOCKER_USERNAME}\",\"password\":\"${DOCKER_PAT}\"}" \
  | jq -r .token)

if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
  echo "[ERROR] Failed to authenticate with Docker Hub."
  exit 1
fi

PAGE=1
TOTAL_DELETED=0

while true; do

  RESPONSE=$(curl -s \
    -H "Authorization: JWT ${TOKEN}" \
    "https://hub.docker.com/v2/repositories/${DOCKER_USERNAME}/${DOCKER_REPOSITORY_NAME}/tags/?page_size=100&page=${PAGE}")

  TAGS=$(echo "$RESPONSE" | jq -r '.results[]?.name')

  if [[ -z "$TAGS" ]]; then
    break
  fi

  for TAG in $TAGS; do

    echo "Deleting tag: $TAG"

    HTTP_CODE=$(curl -s \
      -o /dev/null \
      -w "%{http_code}" \
      -X DELETE \
      -H "Authorization: JWT ${TOKEN}" \
      "https://hub.docker.com/v2/repositories/${DOCKER_USERNAME}/${DOCKER_REPOSITORY_NAME}/tags/${TAG}/")

    if [[ "$HTTP_CODE" == "204" || "$HTTP_CODE" == "202" ]]; then
      TOTAL_DELETED=$((TOTAL_DELETED + 1))
    else
      echo "[WARNING] Failed to delete tag $TAG (HTTP $HTTP_CODE)"
    fi

  done

  PAGE=$((PAGE + 1))

done

echo "[SUCCESS] Deleted $TOTAL_DELETED tags."
echo "Repository remains intact."
