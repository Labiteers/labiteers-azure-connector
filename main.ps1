# Variables
$appName = "Labiteers"
$outputFile = "LabiteersAppDetails.json"

# List all subscriptions for the logged-in account
$subscriptions = az account list --query "[].{Name:name, Id:id}" -o json | ConvertFrom-Json

if ($subscriptions.Count -gt 1) {
    Write-Host "Multiple subscriptions detected. Please select one:"
    for ($i = 0; $i -lt $subscriptions.Count; $i++) {
        Write-Host "$($i+1). $($subscriptions[$i].Name) [$($subscriptions[$i].Id)]"
    }

    do {
        $selection = Read-Host "Enter the number of the subscription to use"
    } while (($selection -lt 1) -or ($selection -gt $subscriptions.Count))

    $subscriptionId = $subscriptions[$selection - 1].Id
    Write-Host "You selected subscription: $($subscriptions[$selection - 1].Name) [$subscriptionId]"
} else {
    $subscriptionId = $subscriptions[0].Id
    Write-Host "Single subscription detected: $($subscriptions[0].Name) [$subscriptionId]"
}

# Set the active subscription
az account set --subscription $subscriptionId

# Create app registration
$app = az ad app create --display-name $appName --query "{appId:appId, id:id}" --output json | ConvertFrom-Json

# Create client secret
$secret = az ad app credential reset --id $app.appId --query "{clientSecret:password}" --output json | ConvertFrom-Json

# Get tenant ID
$tenantId = az account show --query tenantId --output tsv

# Output app info
Write-Host "=============================="
Write-Host "App Name: $appName"
Write-Host "Application (client) ID: $($app.appId)"
Write-Host "Directory (tenant) ID: $tenantId"
Write-Host "Client Secret: $($secret.clientSecret)"
Write-Host "Subscription ID: $subscriptionId"
Write-Host "==============================`n"

# Array of required resource providers
$resourceProviders = @("Microsoft.Network", "Microsoft.Compute")

foreach ($provider in $resourceProviders) {
    # Get the current registration state
    $state = az provider show --namespace $provider --subscription $subscriptionId --query "registrationState" -o tsv

    if ($state -eq "Registered") {
        Write-Host "$provider is already registered."
    } else {
        Write-Host "$provider is not registered. Registering now..."
        az provider register --namespace $provider --subscription $subscriptionId

        # Wait for registration to complete
        do {
            Start-Sleep -Seconds 5
            $state = az provider show --namespace $provider --subscription $subscriptionId --query "registrationState" -o tsv
            Write-Host "Waiting for $provider registration... Current state: $state"
        } while ($state -ne "Registered")

        Write-Host "$provider registration completed!"
    }
}

Write-Host "`nAll required resource providers are registered and ready."

# Save details to a JSON file
$appDetails = @{
    AppName         = $appName
    ApplicationId   = $app.appId
    TenantId        = $tenantId
    SubscriptionId  = $subscriptionId
    ClientSecret    = $secret.clientSecret
}

$appDetails | ConvertTo-Json | Out-File -FilePath $outputFile -Encoding utf8

Write-Host "`nApp registration details saved to $outputFile"
