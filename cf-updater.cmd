@echo off
SETLOCAL EnableDelayedExpansion
:: Your Cloudflare email
set CLOUDFLARE_EMAIL=
:: https://dash.cloudflare.com/*/api-tokens
set CLOUDFLARE_ACCOUNT_API_TOKEN=
:: https://dash.cloudflare.com/profile/api-tokens
set CLOUDFLARE_GLOBAL_API_KEY=
:: https://dash.cloudflare.com/*/example.com
set ZONE_ID=
:: Your domain
set DNS_NAME=

echo [%date% %time%] Loop started
:loop

set "DNS_JSON="
for /f "delims=" %%A in ('curl.exe -s -X GET "https://api.cloudflare.com/client/v4/zones/%ZONE_ID%/dns_records" -H "Authorization: Bearer %CLOUDFLARE_ACCOUNT_API_TOKEN%" -H "Content-Type: application/json"') do (
    set "DNS_JSON=!DNS_JSON!%%A"
)

set "TEMP_JSON=%temp%\cf_dns.json"
echo !DNS_JSON! > "%TEMP_JSON%"

for /f "delims=" %%I in ('
    powershell -NoProfile -Command ^
      "(Get-Content '%TEMP_JSON%' | ConvertFrom-Json).result | Where-Object { $_.name -eq '%DNS_NAME%' } | Select-Object -ExpandProperty id"
') do set "DNS_RECORD_ID=%%I"

del "%TEMP_JSON%"

echo DNS_RECORD_ID="%DNS_RECORD_ID%"

for /f "delims=" %%A in ('curl -s https://ip.me') do set NEW_IP=%%A

echo [%date% %time%] Updating IP...

curl.exe -s -X PATCH "https://api.cloudflare.com/client/v4/zones/%ZONE_ID%/dns_records/%DNS_RECORD_ID%" -H "X-Auth-Email: %CLOUDFLARE_EMAIL%" -H "X-Auth-Key: %CLOUDFLARE_GLOBAL_API_KEY%" -H "Content-Type: application/json" --data "{\"name\":\"%DNS_NAME%\",\"ttl\":3600,\"type\":\"A\",\"comment\":\"%date% %time% - Updated via script\",\"content\":\"%NEW_IP%\",\"proxied\":false}"
timeout /t 3600 /nobreak >nul

goto loop