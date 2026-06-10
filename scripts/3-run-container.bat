@echo off
:: FIX: Using the ~ modifier strips the outer quotes passed from your SSH string safely
set CONTAINER_NAME=%~1
set TARGET_PORT=%~2
set IMAGE_TAG=%~3

echo =======================================================
echo [Step 3/4] Launching Active Container Production Layer
echo =======================================================
echo Name:              %CONTAINER_NAME%
echo Mapping Port:      %TARGET_PORT%
echo Targeting Version: %IMAGE_TAG%

:: Spin up container targeting your fresh safe variables
docker run --name %CONTAINER_NAME% -d -p %TARGET_PORT%:%TARGET_PORT% ^
  --restart unless-stopped ^
  -e SPRING_DATASOURCE_URL=%ONPREM_SERVER_DB_URI% ^
  -e SPRING_DATASOURCE_USERNAME=%ONPREM_SERVER_DB_USERNAME% ^
  -e SPRING_DATASOURCE_PASSWORD=%ONPREM_SERVER_DB_PASSWORD% ^
  -e SPRING_JWT_SECRET=%APP_JWT_SECRET% ^
  -e spring_profile=%DEPLOY_ENV% ^
  %CONTAINER_NAME%:%IMAGE_TAG%

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker run command failed to execute.
    exit /b 1
)

echo [SUCCESS] Step 3 Complete. Container is booting up...
