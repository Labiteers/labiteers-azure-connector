# 🌩️ Labiteers Azure Connector Tool

The **Labiteers Azure Connector Tool** is a PowerShell-based automation script that prepares your Microsoft Azure environment for use with the **Labiteers platform**.  
It automatically registers the required Azure application, configures permissions, and ensures your subscription is ready for smooth integration.

---

## 🚀 What This Tool Does

When you run this tool, it performs the following steps automatically:

1. **Detects your Azure subscriptions** and lets you choose which one to use.
2. **Creates an Azure App Registration** named `Labiteers` in your tenant.
3. **Configures a Redirect URI** for the Labiteers platform (`https://labiteers.com/auth/azure-callback`).
4. **Generates a Client Secret** and records all relevant IDs.
5. **Registers required Azure Resource Providers**:
   - `Microsoft.Network`
   - `Microsoft.Compute`
6. **Creates a Service Principal** for the app.
7. **Grants “Contributor” access** to the Labiteers app on the selected subscription.
8. **Saves all details** (App ID, Tenant ID, Subscription ID, Secret, etc.) to a JSON file for future reference.

At the end of the process, your Azure account will be fully configured to work with the **Labiteers platform**. Please make sure to delete the output file afterward.

---

## 🧰 Prerequisites

Before running the script, ensure that:

- You have an **active Pay-As-You-Go Azure subscription**.
- You have **permissions to create App Registrations and role assignments** (typically an Owner or User Access Administrator).
- You have the **Azure CLI** installed and are logged in.

To check if you’re logged in, run:
```powershell
az login
```

---

## 🧠 Usage

You can run the Labiteers Azure Connector directly in your **Azure Cloud Shell** by executing the following commands:

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Labiteers/labiteers-azure-connector/master/main.ps1" -OutFile "./LabiteersAppSetup.ps1"

./LabiteersAppSetup.ps1