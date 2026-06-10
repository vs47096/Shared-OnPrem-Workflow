@echo off
set PORT=%1
set CONTAINER_NAME=%2

echo =======================================================
echo      Activating Application Health Monitor Layer
echo =======================================================
echo Targeting Endpoint: http://localhost:%PORT%/actuator/health
echo Monitoring Container: %CONTAINER_NAME%

set MAX_ATTEMPTS=12
set ATTEMPT=1

:Loop
echo Checking application status (Attempt %ATTEMPT%/%MAX_ATTEMPTS%)...

:: Use native Windows curl. We extract just the HTTP status code. 
:: If curl hits a connection drop/empty reply, we route the error to nul and handle a blank string.
for /f "delims=" %%i in ('curl -s -o nul -w "%%{http_code}" http://localhost:%PORT%/actuator/health 2^>nul') do set HTTP_CODE=%%i

:: If curl fails completely and returns nothing, force it to 000
if "%HTTP_CODE%"=="" set HTTP_CODE=000

echo Application layer responded with status code: %HTTP_CODE%

if "%HTTP_CODE%"=="200" (
    echo [SUCCESS] Core services are healthy and responding with 200 OK!
    exit /b 0
)

if %ATTEMPT% geq %MAX_ATTEMPTS% goto :Failed

echo Application not ready yet. Retrying in 5 seconds...
timeout /t 5 /nobreak >nul
set /a ATTEMPT+=1
goto :Loop

:Failed
echo.
echo [CRITICAL ERROR] Application failed to report healthy within 60 seconds.
echo === Fetching Last 50 Lines of Active Container Logs ===
docker logs --tail 50 %CONTAINER_NAME%
echo =======================================================
exit /b 1
