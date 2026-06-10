@echo off
echo =======================================================
echo [Step 4/4] Environment Housekeeping & Fragment Cleanup
echo =======================================================

echo Cleaning exited or dead container systems...
for /f "tokens=*" %%C in ('docker ps -a --filter "status=exited" --format "{{.ID}}"') do (
    echo Removing stopped container ID: %%C
    docker rm %%C >nul 2>&1
)

echo Purging unreferenced docker images and dangling layers...
for /f "tokens=*" %%I in ('docker images -q --filter "dangling=true"') do (
    echo Removing dangling layer ID: %%I
    docker rmi -f %%I >nul 2>&1
)

echo [SUCCESS] Step 4 Complete. Server filesystem is clean.
