# 02. Design: CIDR Plan, Subnets, Routes, Security Groups

All numbers here match `config/network-plan.json` (checked by `tests/test_network_plan.py`) and the Terraform defaults.

## 2.1 The diagram's original address ranges, and what I recommend

*(Based on the text description of your diagram. I have not seen the image itself.)*

| | Diagram | Recommended for implementation |
|---|---|---|
| VPC 1 / VPC A | `28.0.0.0/16` | `10.0.0.0/16` |
| VPC 2 / VPC B | `28.200.0.0/16` | `10.1.0.0/16` |

**Do the diagram's ranges work for peering?** Yes. `28.0.0.0/16` covers `28.0.0.0`-`28.0.255.255`, and `28.200.0.0/16` covers `28.200.0.0`-`28.200.255.255`. They do **not** overlap, so AWS would accept the peering.

**Why I still recommend changing them:**

1. `28.0.0.0/8` is **not** one of the private ranges set aside by RFC 1918 (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`). It is ordinary **public** address space belonging to someone else (it is commonly attributed to a US government network; check IANA/ARIN if you need the exact owner).
2. If a server in your VPC tried to reach a real public host in `28.x.x.x`, your route table would send it to your own VPC and the packet would never leave. That is a confusing, hard-to-debug failure.
3. Private ranges are the standard, expected practice and what examiners look for.

**Why these two specific ranges:** `10.0.0.0/16` and `10.1.0.0/16` are far apart, clearly non-overlapping, and each leaves plenty of room (65,536 addresses) to add subnets later.

**If your trainer insists on the original ranges:** change only these values (they are the Terraform variables and the Console CIDR boxes) and re-run the unit tests with an updated `network-plan.json`. Remove the "is RFC 1918" test or mark it as an accepted deviation.

## 2.2 VPC and subnet allocation table

AWS reserves **5 addresses in every subnet** (the first four and the last one), so a `/24` has 251 usable addresses, not 256.

| Name | VPC | CIDR | Type | AZ | Usable range (approx.) | Holds |
|---|---|---|---|---|---|---|
| `peering-lab-vpc-a` | n/a | `10.0.0.0/16` | VPC | n/a | n/a | n/a |
| `peering-lab-a-public` | A | `10.0.1.0/24` | Public | one AZ (e.g. `ap-south-1a`) | `10.0.1.4`-`10.0.1.254` | EC2 `a-public` |
| `peering-lab-a-private` | A | `10.0.2.0/24` | Private | same AZ | `10.0.2.4`-`10.0.2.254` | EC2 `a-private`, Instance Connect Endpoint A |
| `peering-lab-vpc-b` | n/a | `10.1.0.0/16` | VPC | n/a | n/a | n/a |
| `peering-lab-b-private` | B | `10.1.1.0/24` | Private | same AZ | `10.1.1.4`-`10.1.1.254` | EC2 `b-private`, Instance Connect Endpoint B |

Instance IPs are assigned automatically from these ranges. You will read the real values from the Console and use them in the tests. (Do not assume `.4`.)

**Why one AZ?** Traffic over a peering connection that stays in one AZ has no data-transfer charge; traffic that crosses AZs does. Using one AZ for every subnet avoids that charge. The trade-off: no resilience to an AZ failure. This is a networking lab, not a high-availability design. (Project 2 covers multi-AZ.)

## 2.3 Route tables (complete)

Each subnet is **explicitly associated** with its own route table. The VPC's automatic "main" route table is left unused.

### VPC A

| Route table | Associated subnet | Destination | Target | Why |
|---|---|---|---|---|
| `peering-lab-a-public-rt` | `a-public` | `10.0.0.0/16` | local (automatic) | Traffic inside VPC A |
| | | `0.0.0.0/0` | Internet Gateway `peering-lab-a-igw` | Makes the subnet **public** |
| | | `10.1.0.0/16` | Peering connection `peering-lab-a-to-b` | Reach VPC B |
| `peering-lab-a-private-rt` | `a-private` | `10.0.0.0/16` | local (automatic) | Traffic inside VPC A |
| | | `10.1.0.0/16` | Peering connection `peering-lab-a-to-b` | Reach VPC B |
| | | *(no `0.0.0.0/0`)* | n/a | Keeps the subnet **private** (no NAT in this design) |

### VPC B

| Route table | Associated subnet | Destination | Target | Why |
|---|---|---|---|---|
| `peering-lab-b-private-rt` | `b-private` | `10.1.0.0/16` | local (automatic) | Traffic inside VPC B |
| | | `10.0.0.0/16` | Peering connection `peering-lab-a-to-b` | Reach VPC A (the **return route**) |

**Both directions are required.** A request from VPC A to VPC B uses the A-side route. The *reply* uses the B-side route. If either is missing, requests arrive but replies are lost, and it looks like "no connection".

## 2.4 Security-group rules

Security groups are stateful, so you only list the direction that *starts* the conversation.

Placeholders: `MY_IP` = your public IP with `/32` (for example `203.0.113.25/32`).

### SG `peering-lab-eice-a` (attached to Instance Connect Endpoint A)

| Direction | Protocol | Port | Source/Destination | Purpose |
|---|---|---|---|---|
| Inbound | none | none | none (delete all) | Nothing connects *to* the endpoint |
| Outbound | TCP | 22 | `10.0.0.0/16` | Endpoint may open SSH to VPC A instances only |

### SG `peering-lab-eice-b` (attached to Instance Connect Endpoint B)

| Direction | Protocol | Port | Destination | Purpose |
|---|---|---|---|---|
| Inbound | none | none | none | n/a |
| Outbound | TCP | 22 | `10.1.0.0/16` | Endpoint may open SSH to VPC B instances only |

### SG `peering-lab-a-public` (instance `a-public`)

| Direction | Protocol | Port | Source | Purpose |
|---|---|---|---|---|
| Inbound | TCP | 8080 | `MY_IP` | View the test page from your browser |
| Inbound | TCP | 22 | SG `peering-lab-eice-a` | Admin shell via the endpoint only |
| Inbound | ICMP (echo request) | n/a | `10.1.0.0/16` | Ping from VPC B |
| Inbound | TCP | 8080 | `10.1.0.0/16` | Test page from VPC B |
| Outbound | All | All | `0.0.0.0/0` | Default; lets the instance answer and reach the internet |

### SG `peering-lab-a-private` (instance `a-private`)

| Direction | Protocol | Port | Source | Purpose |
|---|---|---|---|---|
| Inbound | TCP | 22 | SG `peering-lab-eice-a` | Admin shell via the endpoint only |
| Inbound | ICMP (echo request) | n/a | `10.0.0.0/16` | Ping from inside VPC A (e.g. from `a-public`) |
| Inbound | ICMP (echo request) | n/a | `10.1.0.0/16` | Ping from VPC B |
| Inbound | TCP | 8080 | `10.0.0.0/16` | Test page from VPC A |
| Inbound | TCP | 8080 | `10.1.0.0/16` | Test page from VPC B |
| Outbound | All | All | `0.0.0.0/0` | Default |

### SG `peering-lab-b-private` (instance `b-private`)

| Direction | Protocol | Port | Source | Purpose |
|---|---|---|---|---|
| Inbound | TCP | 22 | SG `peering-lab-eice-b` | Admin shell via the endpoint only |
| Inbound | ICMP (echo request) | n/a | `10.0.0.0/16` | Ping from VPC A |
| Inbound | TCP | 8080 | `10.0.0.0/16` | Test page from VPC A |
| Outbound | All | All | `0.0.0.0/0` | Default |

**Design choices to mention in your viva:**

- **No rule opens port 22 to the internet.** SSH only comes from the endpoint security groups.
- **Peer rules use CIDR blocks, not security-group references.** (AWS can reference a peer VPC's security group in same-Region peering, but CIDRs are simpler to read and screenshot.) You can tighten later by narrowing `10.1.0.0/16` to the single subnet `10.1.1.0/24`.
- **"Outbound all" is the default and is kept for simplicity.** Production hardening would restrict it too (see `07-production-option.md`).
- **Endpoint setting "Preserve client IP" is OFF.** With it off, the instance sees the endpoint as the source, so the rule "SSH from the endpoint's security group" works. Confirm this against AWS's page "Security groups for EC2 Instance Connect Endpoint" if your Console version words it differently.

## 2.5 IAM permissions you need (for the person doing the lab)

If your lab account gives you broad permissions, you can skip this. If it is restricted, your IAM user needs permission to open the tunnel. An *example* policy is in `config/iam-policy-eice-user-example.json`. Replace `REGION` and `ACCOUNT_ID` with real values, and compare it with AWS's page "Permissions to use EC2 Instance Connect Endpoint to connect to instances" before relying on it. I have not tested it.

## 2.6 Two deployment options

| | **Option 1: Cost-conscious lab (what is built here)** | **Option 2: Production-oriented** |
|---|---|---|
| Availability Zones | One | Two or more |
| Private internet access | None (no NAT) | NAT gateway per AZ, or VPC endpoints |
| Admin access | EC2 Instance Connect Endpoint | Session Manager with VPC endpoints |
| Public instance | One test instance | No public instances; a load balancer in front |
| Monitoring | None beyond defaults | VPC Flow Logs, CloudWatch, GuardDuty |
| Scaling to more VPCs | Peering | Transit Gateway |

Details of Option 2 are in `07-production-option.md`.
