# 06. Cost Considerations and Cleanup

**I have not created any resource, so nothing is costing you money right now.**
I have not quoted prices: they vary by Region and change over time. Always read the current AWS pricing pages.

## What can cost money

| Resource | Charged? | Notes (verify on the pricing pages) |
|---|---|---|
| VPC, subnets, route tables, security groups | No | No separate fee for these |
| Internet Gateway | No charge for the gateway itself | Data transfer *out to the internet* has its own pricing |
| VPC peering connection | **No charge to create** | AWS states data transfer over peering that **stays within one AZ is free**; cross-AZ and cross-Region transfer is charged. All subnets here use one AZ |
| **EC2 instances (3)** | **Yes**, per hour/second while *running* | Check Free Tier/credits in your own Billing console; do not assume |
| **EBS volumes (3 × 8 GiB)** | **Yes**, while they exist | Deleted automatically when instances are terminated (default for root volumes) |
| **Public IPv4 address (1)** | **Yes**, hourly while it exists | AWS charges for public IPv4 addresses; see the *Public IPv4 Address* tab on the Amazon VPC pricing page |
| EC2 Instance Connect Endpoint (2) | AWS docs say **no additional cost** | Cross-AZ data through it is charged; we use one AZ |
| NAT Gateway | **Not used** | Would add an hourly charge plus per-GB processing, so it is deliberately left out |
| VPC Reachability Analyzer | Per analysis (optional tool) | Only if you use it |

## Cost-saving rules for this lab

1. Finish the whole lab in one sitting and **clean up the same day**.
2. Use one Region and **one AZ**.
3. Use the smallest instance type your account allows.
4. Set a **budget alert** before you start.
5. After cleanup, check **Billing → Bills** (or Cost Explorer) the next day. Costs show up with a delay.

## Cleanup: Console route (order matters)

AWS refuses to delete something that another resource still uses. Follow this order.

1. **EC2 → Instances:** select all three `peering-lab-*` instances → **Instance state → Terminate instance**. Wait for **Terminated**.
2. **VPC → Endpoints:** select `peering-lab-eice-a` and `peering-lab-eice-b` → **Actions → Delete endpoint**. Wait until they disappear.
3. **VPC → Peering connections:** select `peering-lab-a-to-b` → **Actions → Delete peering connection**. (Tick the box to also delete related routes if offered.)
4. **VPC → Internet gateways:** select `peering-lab-a-igw` → **Actions → Detach from VPC**, then **Actions → Delete internet gateway**.
5. **VPC → Subnets:** delete the three `peering-lab-*` subnets.
6. **VPC → Route tables:** delete the three `peering-lab-*` custom route tables. (If "delete" is disabled, open **Subnet associations** and make sure nothing is attached.)
7. **EC2 → Security Groups:** delete the five `peering-lab-*` groups. Delete the instance groups first and the endpoint groups last if a dependency error appears (the instance groups reference the endpoint groups).
8. **VPC → Your VPCs:** delete `peering-lab-vpc-a` and `peering-lab-vpc-b`.
9. **Verify:** EC2 → Instances (none running), EC2 → Volumes (none left), EC2 → Elastic IPs and the VPC console (nothing from this lab).
10. Search **Resource Groups & Tag Editor → Tag Editor** for tag `Project = vpc-peering-lab` in your Region to catch anything missed.

## Cleanup: Terraform route

```bash
cd terraform
terraform destroy
```

Type `yes` when asked. Then run the verification in step 9 above. If `destroy` fails part-way, read the error, fix it, and run it again.

## After cleanup

- Delete any downloaded `.pem` files (there should be none in this design).
- Do **not** delete your screenshots: you need them for your submission.
- Keep `terraform.tfstate` **out of Git** (the `.gitignore` already does this).
