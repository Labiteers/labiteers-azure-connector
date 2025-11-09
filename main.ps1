# Variables
$appName = "Labiteers"
$outputFile = "LabiteersCloudSettings.json"
$redirectUri = "https://labiteers.com/auth/azure-callback"

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

# Set web redirect URI
az ad app update --id $app.appId --web-redirect-uris $redirectUri
Write-Host "Web redirect URI set to: $redirectUri"

# Create client secret
$secret = az ad app credential reset --id $app.appId --query "{clientSecret:password}" --output json | ConvertFrom-Json

# Get tenant ID
$tenantId = az account show --query tenantId --output tsv

# Create a Service Principal for the app (if not already created)
$existingSp = az ad sp list --filter "appId eq '$($app.appId)'" --query "[0].id" -o tsv
if (-not $existingSp) {
    Write-Host "Creating Service Principal for app..."
    $sp = az ad sp create --id $app.appId --query "{objectId:id}" --output json | ConvertFrom-Json
    $spId = $sp.objectId
} else {
    Write-Host "Service Principal already exists."
    $spId = $existingSp
}

# Check if the 'Contributor' role is already assigned
Write-Host "Checking if 'Contributor' role is already assigned to the Labiteers app..."
$existingRole = az role assignment list `
    --assignee $app.appId `
    --role "Contributor" `
    --scope "/subscriptions/$subscriptionId" `
    --query "[0].roleDefinitionName" -o tsv

if ($existingRole -eq "Contributor") {
    Write-Host "'Contributor' role is already assigned to this app. Skipping..."
} else {
    Write-Host "Assigning 'Contributor' role to the Labiteers app..."
    az role assignment create --assignee $app.appId --role "Contributor" --scope "/subscriptions/$subscriptionId"
    Write-Host "Role assignment complete."
}

# Output app info
Write-Host "=============================="
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
    ApplicationId   = $app.appId
    TenantId        = $tenantId
    SubscriptionId  = $subscriptionId
    ClientSecret    = $secret.clientSecret
}

$appDetails | ConvertTo-Json | Out-File -FilePath $outputFile -Encoding utf8

Write-Host "`nApp registration details saved to $outputFile"
