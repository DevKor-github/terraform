terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}
variable "github_token" {
  type        = string
  description = "GitHub token"
}
variable "discord_webhook_url" {
  description = "The Discord webhook URL to send notifications"
  type = string
}

# Configure the GitHub Provider
provider "github" {
  token = var.github_token
  owner = "DevKor-github"
}

data "local_file" "users" {
  filename = "${path.module}/users.json"
}

locals {
  users = jsondecode(data.local_file.users.content)
}

data "local_file" "teams" {
  filename = "${path.module}/teams.json"
}

locals {
  teams = jsondecode(data.local_file.teams.content)
}
data "local_file" "repos" {
  filename = "${path.module}/repos.json"
}

locals {
  repos = jsondecode(data.local_file.repos.content)
}
data "local_file" "repo_permissions" {
  filename = "${path.module}/repo_permissions.json"
}

locals {
  repo_permissions = jsondecode(data.local_file.repo_permissions.content)
}


resource "github_organization_settings" "org_settings" {
  billing_email = "devkor.apply@gmail.com"
  company = "DevKor"
  blog = "https://devkor.club"
  email = "devkor.apply@gmail.com"
  location = "Seoul, Korea"
  name = "DevKor"
  description = "고려대학교 SW 프로덕트 학회 DevKor Github Organization"
  has_organization_projects = true
  has_repository_projects = true
  members_can_create_repositories = false
  members_can_create_private_pages = false

  advanced_security_enabled_for_new_repositories = true
  dependabot_alerts_enabled_for_new_repositories = true
  dependabot_security_updates_enabled_for_new_repositories = true
  dependency_graph_enabled_for_new_repositories = true
  secret_scanning_enabled_for_new_repositories = true
  secret_scanning_push_protection_enabled_for_new_repositories = true
}


# user 초대
resource "github_membership" "user" {
  for_each = { for user in local.users : user.user => user }

  username = each.value.user
  role     = each.value.role
}

# team 생성
resource "github_team" "team" {
  for_each = { for team in local.teams : team.name => team }

  name        = each.key
  description = "DevKor ${each.key} team"
  privacy     = "closed"
}

# 팀별 2 repositories 생성
resource "github_repository" "repo" {
  for_each = { for repo in local.repos : repo.name => repo }


  name        = each.key
  description = "DevKor ${each.key} repository"
  visibility = "public"
  has_projects = true
  has_wiki = true
  has_downloads = true
  has_issues = true
  has_discussions = true

  topics = ["devkor"]
  license_template = "MIT"

  archive_on_destroy = true
  vulnerability_alerts = true

  security_and_analysis {
    secret_scanning {
      status =  "enabled"
    }
    secret_scanning_push_protection {
      status = "enabled"
    }
  }

}
# team - repo permission
resource "github_team_repository" "team_repos" {
  for_each = { for permission in local.repo_permissions : "${permission.team}:${permission.repo}" => permission }
  team_id    = github_team.team[each.value.team].id
  repository = each.value.repo
  permission = each.value.permission
}


# main branch must have Reviews
resource "github_organization_ruleset" "review_ruleset" {
  name   = "restrict-repo-deletion"
  target = "branch"

  enforcement = "active"

  conditions {
    ref_name {
      include = [ "main", "deploy" ]
      exclude = []
    }
    repository_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  rules {
    pull_request {
      required_approving_review_count = 1
      require_last_push_approval = true
    }

  }
}


# PR -> discord webhook
resource "github_repository_webhook" "discord_pr_webhook" {
  for_each = { for repo in local.repos : repo.name => repo }

  repository = each.value

  configuration {
    url          = var.discord_webhook_url
    content_type = "json"
    insecure_ssl = false
  }

  events = ["pull_request", "pull_request_review", "pull_request_review_comment"]
}