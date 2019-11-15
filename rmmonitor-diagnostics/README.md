# Monitor Diagnostics

Terraform module to create a diagnostic settings for any resource in Azure. Takes as input the log and metrics categories to apply to the target and destination to send diagnostics to.

## Usage

Example how to create diagnostic settings for a subscription, deployed using [tau](https://github.com/avinor/tau).

```terraform
module {
    source = "avinor/monitor-diagnostics/azurerm"
    version = "1.0.0"
}

inputs {
    name = "subscription"
    destination = "/subscriptions/..../eventhub/..."
    eventhub_name = "diagnostics"

    target_ids = [
        "/subscriptions/000000-00-00-00-000000",
    ]

    logs = [
        "Administrative",
        "Security",
        "ServiceHealth",
        "Alert",
        "Recommendation",
        "Policy",
        "Autoscale",
        "ResourceHealth",
    ]
}
```

## Destination

Destination can be the resource id of either an Event Hub, Log Analytics or Storage Account. Depending on what the resource id is pointing towards it will configure the diagnostic settings differently.

## Categories

If the resource already exists before creating the diagnostic settings it would be possible to use a data source to get all the valid categories. However, if resource does not exist it will still create a valid plan but fail during executing. It will only work when the resource already exists and it can read the categories from resource.

Unless this is fixed in Azure SDK there is no way to get all categories before creating a resource now. So all categories have to be listed as input.
