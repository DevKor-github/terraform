users = [
  {
    user = "overthestream"
    role = "admin"
    team = "kudog"
  },
  {
    user = "overthestream2"
    role = "admin"
    team = "kudog"
  },
]
teams = [
  {
    name = "kudog"
  },
  {
    name = "kukey"
  },
]
repos = [
  {
    name = "kudog-backend"
  },
  {
    name = "kudog-frontend"
  },
]
repo_permissions = [
  {
    repo       = "kudog-frontend",
    team       = "kudog",
    permission = "admin"
  },
  {
    repo       = "kudog-backend",
    team       = "kudog",
    permission = "admin"
  }
]
