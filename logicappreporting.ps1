using namespace System.Net
using namespace System.Net.Http
using namespace System.Text

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

try {
    # Clear any previously loaded modules if needed
    Remove-Module Az -ErrorAction SilentlyContinue
    Remove-Module Az.Accounts -ErrorAction SilentlyContinue
    Remove-Module Az.LogicApp -ErrorAction SilentlyContinue

    # Import the necessary Az modules explicitly
    Import-Module Az.Accounts
    Import-Module Az.LogicApp

    # Authenticate to Azure using managed identity
    $context = Connect-AzAccount -Identity
    if (-not $context) {
        Write-Error "Failed to authenticate using managed identity."
        throw "Failed to authenticate using managed identity."
    }
    Write-Output "Successfully authenticated using managed identity."

    # List all available subscriptions to verify the subscription ID
    $subscriptions = Get-AzSubscription
    Write-Output "Available subscriptions:"
    $subscriptions | ForEach-Object {
        Write-Output "Subscription: $($_.Name) - $($_.Id)"
    }

    # Set the subscription context
    $subscriptionId = "ad744a08-2411-4d78-b417-1f1c83f4f741"
    $subscriptionName = "Pay-As-You-Go-ContractorMarketing"
    $targetSubscription = $subscriptions | Where-Object { $_.Id -eq $subscriptionId }

    if (-not $targetSubscription) {
        $errorMessage = "The specified subscription ID $subscriptionId is not found. Available subscriptions are: $($subscriptions | Format-Table -Property Name, Id -AutoSize | Out-String)"
        Write-Error $errorMessage
        throw $errorMessage
    }

    Set-AzContext -SubscriptionId $subscriptionId

    # Verify the context
    $currentContext = Get-AzContext
    Write-Output "Current context: SubscriptionName=$($currentContext.Subscription.Name), SubscriptionId=$($currentContext.Subscription.Id)"
    if ($currentContext.Subscription.Id -ne $subscriptionId -or $currentContext.Subscription.Name -ne $subscriptionName) {
        Write-Error "Failed to set the subscription context to the correct subscription."
        throw "Failed to set the subscription context to the correct subscription."
    }

    # Define variables
    $resourceGroupName = "ContractorMarketing"
    $logicAppName = "contractormarketing-replygmail-realtime"

    # Fetch the runs for the Logic App in the specified resource group
    $allRuns = Get-AzLogicAppRunHistory -ResourceGroupName $resourceGroupName -Name $logicAppName

    # Ensure that the $allRuns variable is not null
    if (-not $allRuns) {
        Write-Error "Failed to retrieve Logic App run history."
        throw "Failed to retrieve Logic App run history."
    }

    # Define the date range
    $startDate = (Get-Date).Date  # Start from the beginning of today
    $endDate = $startDate.AddDays(1)  # End at the beginning of tomorrow

    # Filter runs based on the date range
    $filteredRuns = $allRuns | Where-Object { $_.StartTime -ge $startDate -and $_.StartTime -lt $endDate }

    # Initialize counters
    $successCount = 0
    $failureCount = 0
    $skippedCount = 0

    # Loop through the filtered runs and count the statuses
    foreach ($run in $filteredRuns) {
        switch ($run.Status) {
            "Succeeded" { $successCount++ }
            "Failed" { $failureCount++ }
            "Skipped" { $skippedCount++ }
        }
    }

    # Prepare the response
    $response = @{
        Date = (Get-Date -Format 'yyyy-MM-dd')
        SucceededRuns = $successCount
        FailedRuns = $failureCount
        SkippedRuns = $skippedCount
    }

    # Output the results
    $responseBody = $response | ConvertTo-Json
    Write-Output "Response Body: $responseBody"

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [System.Net.HttpStatusCode]::OK
        Body = $responseBody
    })
} catch {
    Write-Error "An error occurred: $_"
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [System.Net.HttpStatusCode]::InternalServerError
        Body = "An error occurred: $_"
    })
}
