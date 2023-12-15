module "resolver" {
  source = "../"

  name                = "FQDN-Resolver"
  permission_boundary = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/GELBoundary"
}