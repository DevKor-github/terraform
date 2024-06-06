variable "github_token" {
  type        = string
  description = "GitHub token"
  sensitive   = true
}

variable "discord_webhook_url" {
  description = "The Discord webhook URL to send notifications"
  type        = string
  sensitive   = true
}
