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

variable "teams" {
  type = list(object({
    name                = string
    users               = list(string)
    repos               = list(string)
    discord_webhook_url = string
  }))
}

variable "admins" {
  type = list(string)
}
