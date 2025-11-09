# Variables
$appName = "Labiteers"

# Create app registration
$app = az ad app create --display-name $appName --query "{appId:appId, id:id}" --output json | ConvertFrom-Json

# Create client secret
$secret = az ad app credential reset --id $app.appId --query "{clientSecret:password}" --output json | ConvertFrom-Json

# Get tenant ID
$tenantId = az account show --query tenantId --output tsv

# Output values
Write-Host "App Name: $appName"
Write-Host "Application (client) ID: $($app.appId)"
Write-Host "Directory (tenant) ID: $tenantId"
Write-Host "Client Secret: $($secret.clientSecret)"