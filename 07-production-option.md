# 07. Production-Oriented Option (design only, not built)

The lab design is deliberately small. If this were a real company network, I would change the following. This is **a design discussion for your viva**, not something implemented or priced here.

## Target architecture (described in words)

- **Two or more AZs** in each VPC. Each AZ has a public subnet and a private subnet.
- **No public EC2 instances.** Public traffic enters through an **Application Load Balancer** in the public subnets (Project 2 builds this).
- **Private subnets reach the internet** (for patches) through a **NAT gateway in each AZ**, or, better, through **VPC endpoints** for AWS services, so traffic never leaves AWS's network.
- **Admin access** through **AWS Systems Manager Session Manager** (no inbound ports at all), with the required VPC endpoints.
- **Logging and detection:** VPC Flow Logs to CloudWatch Logs or S3, CloudTrail, GuardDuty.
- **Tighter rules:** security-group outbound restricted; peering routes narrowed from the whole CIDR to the specific subnets that must talk; peer security-group references where supported.
- **Infrastructure as code** and a **separate account per environment**.

## Comparison

| Topic | Lab (built) | Production (design) | Reason for the change |
|---|---|---|---|
| AZs | 1 | 2-3 | Survive an AZ failure |
| Internet from private subnets | None | NAT per AZ or VPC endpoints | Patching, calling AWS APIs |
| NAT cost | $0 | Hourly + per-GB charges | Pay for capability |
| Admin access | EC2 Instance Connect Endpoint | Session Manager | No inbound ports, session logging |
| Public instance | Yes, one test page | None; ALB only | Smaller attack surface |
| Peering routes | Whole VPC CIDRs | Specific subnets | Least privilege |
| Egress rules | Allow all | Restricted | Limit data exfiltration |
| Visibility | Console only | Flow Logs, GuardDuty | Detect abuse |
| Connecting many VPCs | Peering (1 link) | Transit Gateway | Peering needs a link per pair and is not transitive |

## When to choose peering vs Transit Gateway

| | VPC peering | Transit Gateway |
|---|---|---|
| Best for | A few VPCs, simple pairs | Many VPCs, hub-and-spoke |
| Transitive routing | No | Yes (via the hub) |
| Charges | No charge to create the connection; data transfer rules apply | Per attachment-hour, plus per-GB processing (check the pricing page) |

## What I would NOT change

- CIDR planning rule: ranges must never overlap, even between accounts and on-premises networks that may connect later.
- Private subnets have no route to the Internet Gateway.
- No SSH/RDP open to `0.0.0.0/0`.
