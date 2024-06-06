variable "github_token" {
  type        = string
  description = "GitHub token"
}

variable "discord_webhook_url" {
  description = "The Discord webhook URL to send notifications"
  type = string
}
