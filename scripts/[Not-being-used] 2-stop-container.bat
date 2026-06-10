@echo off
set CONTAINER_NAME=%1
set OLD_CONTAINER_NAME=%2

echo =======================================================
echo [Step 2/4] Stopping and Renaming Pre-existing Container
echo =======================================================
echo Target Container: %CONTAINER_NAME%
echo Backup Target:    %OLD_CONTAINER_NAME%

:: Check if the container exists (running or stopped)
docker ps -a --format "{{.Names}}" | findstr /i "^%CONTAINER_NAME%$" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Found existing container [%CONTAINER_NAME%]. Processing environment shift...
    
    :: Check if it is currently running, stop it if it is
    docker ps --format "{{.Names}}" | findstr /i "^%CONTAINER_NAME%$" >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo Stopping active container...
        docker stop %CONTAINER_NAME% >nul 2>&1
    )
    
    :: Remove any existing backup container from a previous bad run to avoid conflict
    docker ps -a --format "{{.Names}}" | findstr /i "^%OLD_CONTAINER_NAME%$" >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo Removing stale backup container [%OLD_CONTAINER_NAME%]...
        docker rm -f %OLD_CONTAINER_NAME% >nul 2>&1
    )

    :: Rename current to old
    echo Renaming %CONTAINER_NAME% to %OLD_CONTAINER_NAME%...
    docker rename %CONTAINER_NAME% %OLD_CONTAINER_NAME%
) else (
    echo Clean State: No conflicting active container found. Moving forward.
)

echo [SUCCESS] Step 2 Complete.
