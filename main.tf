terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

# Configure the GitHub Provider
provider "github" {
  token = var.github_token
  owner = "DevKor-github"
}

# team 생성
resource "github_team" "team" {
  for_each = { for team in var.teams : team.name => team }

  name        = each.key
  description = "DevKor ${each.key} team"
  privacy     = "closed"
}

# 팀별 2 repositories 생성
resource "github_repository" "repo" {
  for_each = { for repo in var.repos : repo.name => repo }


  name            = each.key
  description     = "DevKor ${each.key} repository"
  visibility      = "public"
  has_projects    = true
  has_wiki        = true
  has_downloads   = true
  has_issues      = true
  has_discussions = true

  topics           = ["devkor"]
  license_template = "MIT"

  archive_on_destroy   = true
  vulnerability_alerts = true

  security_and_analysis {
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_push_protection {
      status = "enabled"
    }
  }

}
# team - repo permission
resource "github_team_repository" "team_repos" {
  for_each   = { for permission in var.repo_permissions : "${permission.team}:${permission.repo}" => permission }
  team_id    = github_team.team[each.value.team].id
  repository = each.value.repo
  permission = each.value.permission
}


resource "github_branch" "main" {
  for_each = { for repo in var.repos : repo.name => repo }

  repository = each.value.name
  branch     = "main"
}

resource "github_branch_default" "default" {
  for_each = { for repo in var.repos : repo.name => repo }

  repository = each.value.name
  branch     = "main"
}

# main branch must have Reviews
resource "github_repository_ruleset" "review_ruleset" {
  name     = "require_reviews"
  target   = "branch"
  for_each = { for repo in var.repos : repo.name => repo }

  repository  = each.value.name
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    pull_request {
      required_approving_review_count = 1
      require_last_push_approval      = true
    }

  }
}


# PR -> discord webhook
resource "github_repository_webhook" "discord_pr_webhook" {
  for_each = { for repo in var.repos : repo.name => repo }

  repository = each.value.name

  configuration {
    url          = var.discord_webhook_url
    content_type = "json"
    insecure_ssl = false
  }

  events = ["pull_request", "pull_request_review", "pull_request_review_comment"]
}
