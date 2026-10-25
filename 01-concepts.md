# 01. Concepts in Simple English

Read this before touching the AWS Console. Every term is explained when it first appears.

## The big picture

Imagine AWS as a huge apartment building owned by Amazon. You rent a private section of it. Inside your section you build **rooms (networks)**, put **computers** in them, and decide **who may walk in and out**. That is what this project practises.

## Core terms

| Term | Plain-English meaning | In this project |
|---|---|---|
| **Region** | A geographic area where AWS has data centres (e.g. Mumbai = `ap-south-1`). | We use one Region. |
| **Availability Zone (AZ)** | One data-centre group inside a Region (e.g. `ap-south-1a`). | We put everything in **one** AZ to avoid data-transfer charges between AZs. |
| **VPC** (Virtual Private Cloud) | Your own private network inside AWS. Like a fenced plot of land. | VPC A and VPC B. |
| **IP address** | A number that identifies a computer on a network (e.g. `10.0.1.25`). | Every EC2 instance gets a private one. |
| **CIDR range** | A compact way to write a block of IP addresses, e.g. `10.0.0.0/16`. The number after `/` says how many addresses: smaller number = bigger block. `/16` = 65,536 addresses. `/24` = 256 addresses. | VPC A `10.0.0.0/16`, VPC B `10.1.0.0/16`. |
| **Subnet** | A smaller slice of a VPC's range, living in one AZ. Like a room inside the plot. | `10.0.1.0/24`, `10.0.2.0/24`, `10.1.1.0/24`. |
| **Public subnet** | A subnet whose route table sends internet traffic to an Internet Gateway. | VPC A public subnet. |
| **Private subnet** | A subnet with **no** route to an Internet Gateway. Computers there cannot be reached from the internet. | VPC A private, VPC B private. |
| **Route table** | A list of rules: "traffic going to *this* address range, send it to *that* target". Each subnet uses exactly one. | One per subnet in this lab. |
| **Internet Gateway (IGW)** | The door between a VPC and the public internet. | Attached to VPC A only. |
| **Security group (SG)** | A firewall around an instance. Lists what traffic is allowed **in** (and out). **Stateful**: replies to allowed requests are allowed automatically. Default: nothing allowed in. | One per instance. |
| **EC2 instance** | A virtual computer you rent by the hour. | Three small Linux instances. |
| **VPC peering** | A private link between two VPCs so their computers can talk using private IPs, as if on one network. | A to B. |
| **EC2 Instance Connect Endpoint (EICE)** | A managed doorway that lets *you* open a shell on a private instance through AWS, authorised by your IAM identity. No public IP, no bastion. | One in each VPC. |

## How a route table decides (the key idea)

Every route table has a rule called **local**: traffic to an address inside the VPC stays inside the VPC. You add more rules. When a packet leaves an instance, AWS picks the **most specific matching rule**.

Example: `a-public-rt`

| Destination | Target | Meaning |
|---|---|---|
| `10.0.0.0/16` | local | Inside VPC A: deliver directly. |
| `10.1.0.0/16` | peering connection | Going to VPC B: send through the peering link. |
| `0.0.0.0/0` | Internet Gateway | Everything else: send to the internet. |

`0.0.0.0/0` means "every address". Because `10.1.0.0/16` is more specific, VPC B traffic uses the peering link, not the internet.

## What is VPC peering, exactly?

A **peering connection** is a network link between two VPCs. Traffic stays on AWS's private network. It is not a VPN and not a gateway you manage; AWS builds it from existing infrastructure.

Setting it up is always these steps:

1. **Request**: one VPC (the *requester*) asks to peer with another (the *accepter*).
2. **Accept**: the owner of the accepter VPC accepts. (Same account: you click both.)
3. **Routes**: add a route **in both VPCs' route tables** pointing the *other* VPC's CIDR at the peering connection. Peering does nothing until routes exist.
4. **Security groups**: allow the traffic you want (the default blocks everything).

Rules AWS enforces:

- The two VPCs' CIDR blocks **must not overlap**. If both used `10.0.0.0/16`, AWS could not tell which side an address belongs to, so it refuses to peer them.
- Only **one** peering connection can exist between the same two VPCs at a time.

## Why VPC peering is NOT transitive

"Transitive" means: if A is connected to B, and B is connected to C, then A can reach C **through B**. Peering does **not** work that way.

```
A <--peering--> B <--peering--> C        A cannot reach C through B.
```

For A and C to talk you need a **third, direct** peering connection A-C.

Why? Peering is a one-to-one link between exactly two VPCs. Each VPC's route table only knows about *its own* peering connection and only accepts traffic whose source and destination belong to the two peered VPCs.

Two practical consequences that matter for **this** project:

1. **No "edge-to-edge" routing.** VPC B cannot use VPC A's Internet Gateway to reach the internet, even though A has one and B is peered with A. We will prove this in the test `T7`: `b-private` should be blocked from the internet.
2. **Scaling problem.** With many VPCs you would need a connection between every pair (a "full mesh"). That is why AWS Transit Gateway exists for larger networks (see `07-production-option.md`).

## Internet Gateway vs NAT Gateway

| | Internet Gateway (IGW) | NAT Gateway |
|---|---|---|
| Job | Two-way door between a VPC and the internet. | One-way helper: lets **private** instances start connections out to the internet; blocks connections coming in. |
| Instances need a public IP? | Yes, to be reached/reach out. | No. The NAT gateway has the public IP. |
| Lives in | Attached to the VPC. | A **public** subnet. |
| Cost | No charge for the gateway itself. | Hourly charge plus per-GB processing charge (check the VPC pricing page). |
| Used here? | **Yes**, VPC A only. | **No.** |

**Is NAT needed in our design? No.** Our private instances only need to (1) talk to each other through the peering link and (2) be reached by an admin through the Instance Connect Endpoint. The web page they serve uses Python, which is already installed, so they never download anything. Leaving NAT out saves money and keeps the private instances truly isolated. In a production system the servers would usually need NAT (or VPC endpoints) for OS updates.

## Public vs private instances: which and why

| Instance | Subnet | Public IP? | Why |
|---|---|---|---|
| `a-public` | VPC A public | Yes | Demonstrates the Internet Gateway path. The only thing exposed is a test page on port 8080, and only to **your** IP. |
| `a-private` | VPC A private | No | Represents a backend server (app/database tier). Must not be reachable from the internet. |
| `b-private` | VPC B private | No | Represents a backend in another VPC/team/account. Reachable only via the peering link. |

## Secure access to private instances (no public SSH/RDP)

**The problem:** you cannot SSH to a machine that has no public IP, and opening port 22 to the internet invites attackers.

**Our solution: EC2 Instance Connect Endpoint (EICE).**

1. You click *Connect* in the Console (or run one CLI command).
2. AWS checks your **IAM permissions**.
3. AWS pushes a one-time SSH key to the instance for about 60 seconds.
4. The endpoint, which sits **inside** the VPC, forwards your connection to the instance on port 22.

Result: port 22 is open **only to the endpoint's security group**, never to the internet. Connections are logged in AWS CloudTrail. There is no `.pem` key file to lose.

Notes:

- An endpoint can only reach instances in **its own VPC**. That is why there is one endpoint per VPC.
- AWS states there is no additional charge for the endpoint; data crossing AZ boundaries is charged. We use a single AZ.

**Other options (for your viva/interview):**

| Option | How it works | Trade-off |
|---|---|---|
| Bastion host (jump box) | A public instance you SSH into first, then hop. | You must patch, secure and pay for it. More exposed surface. |
| AWS Systems Manager Session Manager | Browser/CLI shell via an agent, no inbound port at all. | Needs the SSM agent, an IAM role on the instance, and either NAT or three interface VPC endpoints (which cost money). |
| VPN / Direct Connect | Your office network joins the VPC. | Overkill for a lab. |

## EC2 security groups vs network ACLs (a common exam question)

| | Security group | Network ACL |
|---|---|---|
| Attached to | Instance (network interface) | Subnet |
| Stateful? | **Yes** | **No** (must allow replies explicitly) |
| Rules | Allow only | Allow and deny |
| Default in this lab | Deny all inbound | Default NACL allows all |

This lab uses security groups for all control and leaves the default NACLs alone.
