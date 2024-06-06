resource "github_organization_settings" "org_settings" {
  billing_email                    = "devkor.apply@gmail.com"
  company                          = "DevKor"
  blog                             = "https://devkor.club"
  email                            = "devkor.apply@gmail.com"
  location                         = "Seoul, Korea"
  name                             = "DevKor"
  description                      = "고려대학교 SW 프로덕트 학회 DevKor Github Organization"
  has_organization_projects        = true
  has_repository_projects          = true
  members_can_create_repositories  = false
  members_can_create_private_pages = false

  advanced_security_enabled_for_new_repositories               = true
  dependabot_alerts_enabled_for_new_repositories               = true
  dependabot_security_updates_enabled_for_new_repositories     = true
  dependency_graph_enabled_for_new_repositories                = true
  secret_scanning_enabled_for_new_repositories                 = true
  secret_scanning_push_protection_enabled_for_new_repositories = true
}

resource "github_membership" "user" {
  for_each = { for user in var.users : user.user => user }

  username = each.value.user
  role     = each.value.role
}
