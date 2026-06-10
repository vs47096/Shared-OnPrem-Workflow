@echo off
set REMOTE_IMAGE=%1
set TAG_NAME=%2

echo =======================================================
echo [Step 1/4] Pulling and Tagging Image from Docker Hub
echo =======================================================
echo Target Image: %REMOTE_IMAGE%
echo Local Tag:    %TAG_NAME%

docker --config C:\Windows\Temp\ pull %REMOTE_IMAGE%
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to pull image from Docker Hub.
    exit /b 1
)

docker tag %REMOTE_IMAGE% %TAG_NAME%
docker rmi %REMOTE_IMAGE%
echo y | docker image prune

echo [SUCCESS] Step 1 Complete.
