module "simple" {
    source = "../../"

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