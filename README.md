# Terraform (optional alternative to the Console guide)

**Creating resources with this configuration costs money. Do not run `apply` until you have read `../docs/06-cost-and-cleanup.md` and approve the costs.**

Terraform reads these files and creates (or deletes) all AWS resources for you. It builds the same design as the Console guide.

## Files

| File | Contents |
|---|---|
| `versions.tf` | Terraform and AWS provider version requirements |
| `providers.tf` | AWS provider and default tags (no credentials) |
| `variables.tf` | All inputs: Region, CIDRs, your IP, instance type |
| `network.tf` | VPCs, subnets, Internet Gateway, route tables |
| `peering.tf` | Peering connection and the three peering routes |
| `security.tf` | Security groups and rules |
| `compute.tf` | EC2 instances and the two Instance Connect Endpoints |
| `outputs.tf` | IDs, IPs and connect commands |
| `terraform.tfvars.example` | Copy to `terraform.tfvars` and edit |

The start-up script is shared with the Console route: `../config/user-data.sh.tpl`.

## What was verified, and what was not

| Verified offline in the build sandbox | Not verified |
|---|---|
| `fmt` clean; all files parse; every reference resolves; start-up template renders | `terraform validate` with the real AWS provider; `plan`; `apply`. **No AWS resources were created by me.** |

## Prerequisites

1. Terraform 1.5 or newer (https://developer.hashicorp.com/terraform/install).
2. AWS CLI v2, signed in to a **lab** account with `aws configure` or `aws sso login`. Never paste keys into `.tf` files.
3. Your public IP as `x.x.x.x/32`.

## Run it

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # then edit allowed_web_cidr
terraform init
terraform validate        # no AWS credentials needed for this
terraform plan            # read the list: expect 3 instances, 2 endpoints, 2 VPCs, ...
# STOP: only continue if you approve the costs
terraform apply
```

Connect (AWS CLI v2) with the commands printed in the `connect_commands` output, or use the Console *Connect* button.

## Clean up (same day!)

```bash
terraform destroy
```

Then check the Console for leftovers (see `../docs/06-cost-and-cleanup.md`).

## Notes

- Terraform state (`terraform.tfstate`) can contain sensitive values. It is git-ignored. Never commit it.
- The peering uses `auto_accept = true`, valid because both VPCs are in the same account and Region.
- The default AZ is the first available AZ in the Region. Set `availability_zone` if your instance type is not offered there.
- Resource names/versions can change with new provider releases. If `terraform validate` reports an argument error, check the provider documentation for that resource and tell me the exact message.
