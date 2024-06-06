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

variable "users" {
  type = list(object({
    user = string
    role = string
    team = string
  }))
}

variable "teams" {
  type = list(object({
    name = string
  }))
}

variable "repos" {
  type = list(object({
    name = string
  }))
}

variable "repo_permissions" {
  type = list(object({
    repo       = string
    team       = string
    permission = string
  }))
}

variable "admins" {
  type = list(string)
}
