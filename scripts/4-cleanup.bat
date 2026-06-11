@echo off
echo =======================================================
echo       Environment Housekeeping and Cleanup
echo =======================================================

echo Removing stopped containers...
docker container prune -f

echo Removing unused images...
docker image prune -a -f

echo Removing unused networks...
docker network prune -f

echo [SUCCESS] Complete. Server filesystem is clean.
