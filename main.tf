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

locals {
  members = setsubtract(flatten(var.teams[*].users), var.admins)
  repos   = flatten(var.teams[*].repos)
  repo_team_mapping = flatten(
    [
      for team in var.teams :
      [for repo in team.repos : { key : repo, value : team.name }]
    ]
  )
  repo_discord_webhook_url_mapping = flatten(
    [
      for team in var.teams :
      [for repo in team.repos : { key : "${team.name}_${repo}", value : { repo : repo, webhook : team.discord_webhook_url } }]
    ]
  )
}

resource "github_membership" "members" {
  for_each = { for member in local.members : member => {} }

  username = each.key
  role     = "member"
}

resource "github_team" "teams" {
  for_each = { for team in var.teams : team.name => {} }

  name        = each.key
  description = "DevKor ${each.key} team"
  privacy     = "closed"
}

resource "github_repository" "repo" {
  for_each = { for repo in local.repos : repo => {} }


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
  for_each   = { for mapping in local.repo_team_mapping : mapping.key => mapping.value }
  team_id    = github_team.teams[each.value].id
  repository = github_repository.repo[each.key].name
  permission = "admin"
}


resource "github_branch" "main" {
  for_each = { for repo in local.repos : repo => {} }

  repository = github_repository.repo[each.key].name
  branch     = "main"
}

resource "github_branch_default" "default" {
  for_each = { for repo in local.repos : repo => {} }

  repository = github_repository.repo[each.key].name
  branch     = "main"
}

# main branch must have Reviews
resource "github_repository_ruleset" "review_ruleset" {
  for_each = { for repo in local.repos : repo => {} }

  name   = "require_reviews"
  target = "branch"

  repository  = github_repository.repo[each.key].name
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
  for_each = { for mapping in local.repo_discord_webhook_url_mapping : mapping.key => mapping.value }

  repository = github_repository.repo[each.value.repo].name

  configuration {
    url          = each.value.webhook
    content_type = "json"
    insecure_ssl = false
  }

  events = ["pull_request", "pull_request_review", "pull_request_review_comment"]
}
