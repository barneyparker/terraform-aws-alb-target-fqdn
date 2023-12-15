# Terraform AWS ALB Target FQDN

This module updates ALB/NLB Target Group members according to an FQDN provided via a tag

## Usage

```hcl
module "resolver" {
  source = "../"

  name                = "FQDN-Resolver"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the module | `string` | n/a | yes |
| log\_retention\_days | Number of days to retain logs | `number` | `7` | no |
| permission\_boundary | ARN of the IAM policy to use as a permission boundary for the role | `string` | `null` | no |
| cron\_schedule | Schedule expression for the Lambda function | `string` | `"cron(0/5 * * * ? *)"` | no |
| fqdn_tag | Tag to use to identify the FQDN to resolve | `string` | `"FQDN"` | no |

## Outputs

N/A
