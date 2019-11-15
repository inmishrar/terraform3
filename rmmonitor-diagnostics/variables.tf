variable "name" {
  description = "Name of Diagnostic settings."
}

variable "destination" {
  description = "Destination for events, either Event Hub, Log Analytics or a Storage account."
}

variable "target_ids" {
  description = "List of resource ids to create diagnostic settings for."
  type        = list(string)
}

variable "eventhub_name" {
  description = "Event Hub name if destination is an event hub."
  default     = null
}

variable "logs" {
  description = "List of log categories to log."
  type        = list(string)
  default     = []
}

variable "metrics" {
  description = "List of metric categories to track."
  type        = list(string)
  default     = []
}