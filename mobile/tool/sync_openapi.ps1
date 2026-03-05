param(
  [string]$ApiBaseUrl = 'https://subtrack-server.vercel.app',
  [string]$OutFile = 'openapi/openapi.json'
)

$target = ($ApiBaseUrl.TrimEnd('/')) + '/api/openapi.json'
Write-Host "Downloading OpenAPI from $target"
Invoke-WebRequest -Uri $target -OutFile $OutFile
Write-Host "Saved to $OutFile"
