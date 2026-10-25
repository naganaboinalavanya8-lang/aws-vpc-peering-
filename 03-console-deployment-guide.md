# 03. AWS Console Deployment Guide

**You execute every step here. Nothing has been deployed by me.**
Menu names can change slightly over time; if a label differs, look for the closest one.

## 0. Before you start

### 0.1 Cost warning (read `06-cost-and-cleanup.md` first)

These resources create charges while they exist: **3 EC2 instances**, their **EBS disks**, and **1 public IPv4 address**. Peering connection creation is free; data transfer inside one AZ over peering is free (cross-AZ is not). The Instance Connect Endpoint has no additional charge per AWS's documentation. Plan to finish and **clean up the same day**.

### 0.2 Safety checklist

- [ ] Sign in with an **IAM user** (or SSO role), not the root user.
- [ ] Billing alert set (Billing console → Budgets → Create budget → "Zero spend budget" or a small monthly budget).
- [ ] Choose **one Region** (top-right dropdown) and stay in it for the whole lab. This guide assumes Mumbai `ap-south-1`. Check that the Region you choose supports EC2 Instance Connect Endpoint.
- [ ] Find your public IP (search "what is my IP"). Write it as `x.x.x.x/32`. This is `MY_IP`.
- [ ] Decide your **one AZ**, for example `ap-south-1a`. Use the **same AZ for every subnet**.
- [ ] Naming: use the prefix `peering-lab-` and tag everything `Project = vpc-peering-lab` where the wizard offers tags.

### 0.3 Order of work

VPCs → subnets → Internet Gateway → route tables → security groups → endpoints → instances → peering → peering routes → test.

---

## Step 1. Create VPC A

1. In the top search bar type **VPC** and open it.
2. Left menu: **Your VPCs** → **Create VPC**.
3. **Resources to create:** choose **VPC only**.
4. **Name tag:** `peering-lab-vpc-a`
5. **IPv4 CIDR block:** choose **IPv4 CIDR manual input**, then enter `10.0.0.0/16`.
6. **IPv6 CIDR block:** No IPv6 CIDR block. **Tenancy:** Default.
7. Add tag: Key `Project`, Value `vpc-peering-lab`.
8. Click **Create VPC**.

📸 Screenshot `01-vpc-a-and-b-overview.png` is taken after Step 2.

## Step 2. Create VPC B

Repeat Step 1 with name `peering-lab-vpc-b` and IPv4 CIDR `10.1.0.0/16`.

Now open **Your VPCs** and confirm both rows show different CIDRs. 📸 **Screenshot 01.**

## Step 3. Create the three subnets

1. Left menu: **Subnets** → **Create subnet**.
2. **VPC ID:** select `peering-lab-vpc-a`.
3. **Subnet 1 of 2:** name `peering-lab-a-public`, **Availability Zone** = your chosen AZ, **IPv4 subnet CIDR block** = `10.0.1.0/24`.
4. Click **Add new subnet**. **Subnet 2 of 2:** name `peering-lab-a-private`, same AZ, CIDR `10.0.2.0/24`.
5. Click **Create subnet**.
6. Repeat **Create subnet** for VPC B: VPC `peering-lab-vpc-b`, name `peering-lab-b-private`, **same AZ**, CIDR `10.1.1.0/24`.

📸 **Screenshot `02-subnets.png`:** Subnets list showing the three subnets, their VPC, CIDR and AZ.

> A subnet is not "public" or "private" because of its name. It becomes public only when its route table has a route to an Internet Gateway (Step 5).

## Step 4. Create and attach the Internet Gateway (VPC A only)

1. Left menu: **Internet gateways** → **Create internet gateway**.
2. Name: `peering-lab-a-igw` → **Create internet gateway**.
3. On the next page click **Actions → Attach to VPC**, choose `peering-lab-vpc-a`, click **Attach internet gateway**.
4. Status should show **Attached**.

## Step 5. Create route tables and associate subnets

1. Left menu: **Route tables** → **Create route table**.
2. Name `peering-lab-a-public-rt`, VPC `peering-lab-vpc-a` → **Create route table**.
3. Repeat for `peering-lab-a-private-rt` (VPC A) and `peering-lab-b-private-rt` (VPC B).

**Associate the subnets** (do this for each route table):

1. Select the route table → tab **Subnet associations** → **Edit subnet associations**.
2. Tick the matching subnet (`a-public` → `a-public-rt`; `a-private` → `a-private-rt`; `b-private` → `b-private-rt`) → **Save associations**.

**Make the public subnet public:**

1. Select `peering-lab-a-public-rt` → tab **Routes** → **Edit routes** → **Add route**.
2. **Destination:** `0.0.0.0/0`. **Target:** **Internet Gateway** → choose `peering-lab-a-igw`. → **Save changes**.

Do **not** add a `0.0.0.0/0` route to either private route table.

(Peering routes are added in Step 10, after the peering connection exists.)

## Step 6. Create the security groups

1. Open **EC2** → left menu **Network & Security → Security Groups** → **Create security group**.

Create these five. For each: set name, description, **VPC**, then rules. Remove the default outbound rule only where stated.

### 6.1 `peering-lab-eice-a` (VPC A)

- Description: `Instance Connect Endpoint A`
- **Inbound rules:** none (leave empty).
- **Outbound rules:** delete the default "All traffic" rule. Add: Type **SSH**, Destination **Custom** `10.0.0.0/16`.

### 6.2 `peering-lab-eice-b` (VPC B)

- Same as above but VPC `peering-lab-vpc-b`, outbound SSH to `10.1.0.0/16`.

### 6.3 `peering-lab-a-public` (VPC A)

Inbound rules:

| Type | Port | Source |
|---|---|---|
| Custom TCP | 8080 | **My IP** (the dropdown fills your IP as `/32`) |
| SSH | 22 | Custom → pick `peering-lab-eice-a` from the list |
| All ICMP - IPv4 | all | Custom `10.1.0.0/16` |
| Custom TCP | 8080 | Custom `10.1.0.0/16` |

Leave outbound as the default (All traffic).

### 6.4 `peering-lab-a-private` (VPC A)

| Type | Port | Source |
|---|---|---|
| SSH | 22 | `peering-lab-eice-a` |
| All ICMP - IPv4 | all | `10.0.0.0/16` |
| All ICMP - IPv4 | all | `10.1.0.0/16` |
| Custom TCP | 8080 | `10.0.0.0/16` |
| Custom TCP | 8080 | `10.1.0.0/16` |

### 6.5 `peering-lab-b-private` (VPC B)

| Type | Port | Source |
|---|---|---|
| SSH | 22 | `peering-lab-eice-b` |
| All ICMP - IPv4 | all | `10.0.0.0/16` |
| Custom TCP | 8080 | `10.0.0.0/16` |

📸 **Screenshot `03-security-group-rules.png`:** the **Inbound rules** tab of `peering-lab-a-private` (and optionally the others). **Check that no rule shows `0.0.0.0/0` on port 22.**

## Step 7. Create the EC2 Instance Connect Endpoints

1. Open **VPC** → left menu **Endpoints** → **Create endpoint**.
2. Name: `peering-lab-eice-a`.
3. **Service category:** choose **EC2 Instance Connect Endpoint**.
4. **VPC:** `peering-lab-vpc-a`. **Security groups:** `peering-lab-eice-a`.
5. **Subnet:** `peering-lab-a-private`.
6. If you see **Preserve client IP**, leave it **off**.
7. **Create endpoint**. Wait until the status is **Available** (a few minutes).
8. Repeat for VPC B: name `peering-lab-eice-b`, VPC `peering-lab-vpc-b`, SG `peering-lab-eice-b`, subnet `peering-lab-b-private`.

> Only one endpoint can exist per VPC per subnet, and an endpoint only reaches instances in its own VPC. That is why we create two.

## Step 8. Launch the three EC2 instances

Open **EC2 → Instances → Launch instances**. Do this three times with the values below.

| Setting | `a-public` | `a-private` | `b-private` |
|---|---|---|---|
| Name | `peering-lab-a-public` | `peering-lab-a-private` | `peering-lab-b-private` |
| VPC | `peering-lab-vpc-a` | `peering-lab-vpc-a` | `peering-lab-vpc-b` |
| Subnet | `peering-lab-a-public` | `peering-lab-a-private` | `peering-lab-b-private` |
| Auto-assign public IP | **Enable** | **Disable** | **Disable** |
| Security group | `peering-lab-a-public` | `peering-lab-a-private` | `peering-lab-b-private` |
| `SERVER_NAME` in user data | `a-public` | `a-private` | `b-private` |

Settings common to all three:

1. **Application and OS Images:** **Amazon Linux 2023 AMI** (64-bit x86).
2. **Instance type:** `t3.micro` (or the type labelled "Free tier eligible" in your account; check your own Free Tier/credits status in the Billing console. Do not assume).
3. **Key pair:** **Proceed without a key pair**. (We connect with Instance Connect Endpoint; there is no `.pem` file to leak.)
4. **Network settings → Edit:** set VPC, Subnet, Auto-assign public IP, and choose **Select existing security group** as in the table.
5. **Configure storage:** 8 GiB `gp3`. Expand **Advanced** and set **Encrypted** = Yes if shown.
6. **Advanced details:**
   - **Metadata version:** **V2 only (token required)**.
   - **User data:** paste the contents of `config/user-data.sh.tpl`, **but first edit the line** `SERVER_NAME="${server_name}"` so it reads, for example, `SERVER_NAME="a-public"`. (Terraform fills that line automatically; in the Console you do it by hand.)
7. Tags: `Project = vpc-peering-lab`.
8. **Launch instance**. Wait for **Instance state = Running** and **Status check = 2/2 checks passed**.

📸 **Screenshot `04-ec2-instances.png`:** the Instances list with columns for Name, Instance ID, Subnet ID, Private IPv4, Public IPv4. **Only `a-public` should have a public IPv4.** Blur account details.

Write down the three private IPs. You need them for testing:

| Instance | Private IP (fill in) |
|---|---|
| a-public | |
| a-private | |
| b-private | |

## Step 9. Create and accept the VPC peering connection

1. **VPC → Peering connections → Create peering connection.**
2. **Name:** `peering-lab-a-to-b`.
3. **VPC ID (Requester):** `peering-lab-vpc-a`.
4. **Account:** **My account**. **Region:** **This Region**.
5. **VPC ID (Accepter):** `peering-lab-vpc-b`.
6. Click **Create peering connection**. Status becomes **Pending acceptance**.
7. Select the new connection → **Actions → Accept request** → **Accept request**.
8. Status becomes **Active** (it may pass through "Provisioning").

> In real life the two VPCs are often in different accounts: the requester creates the request and the *other* account's owner accepts it. Because both VPCs are yours, you do both clicks.

📸 **Screenshot `05-peering-active.png`:** the peering connection details showing Status **Active**, the requester and accepter VPC IDs and CIDRs.

## Step 10. Add the peering routes (both directions)

For each row: **VPC → Route tables** → select the table → **Routes → Edit routes → Add route** → set Destination, then Target **Peering Connection** → `peering-lab-a-to-b` → **Save changes**.

| Route table | Destination | Target |
|---|---|---|
| `peering-lab-a-public-rt` | `10.1.0.0/16` | Peering Connection `peering-lab-a-to-b` |
| `peering-lab-a-private-rt` | `10.1.0.0/16` | Peering Connection `peering-lab-a-to-b` |
| `peering-lab-b-private-rt` | `10.0.0.0/16` | Peering Connection `peering-lab-a-to-b` |

📸 **Screenshot `06-route-tables.png`:** take **three** images (or one combined) showing the Routes tab of each route table. `a-public-rt` must show `local`, `0.0.0.0/0 → igw-…`, and `10.1.0.0/16 → pcx-…`. The private tables must show **no** `0.0.0.0/0`.
(Name them `06a-a-public-routes.png`, `06b-a-private-routes.png`, `06c-b-private-routes.png`.)

## Step 11. Connect to an instance and test

Go to `04-testing.md`.

To open a shell (summary): **EC2 → Instances →** select an instance **→ Connect → EC2 Instance Connect tab → Connection type: "Connect using EC2 Instance Connect Endpoint" →** choose the endpoint **→ Username `ec2-user` → Connect.**

## Step 12. Clean up

Follow `06-cost-and-cleanup.md`. Do not leave the lab running overnight.

---

## Optional: Terraform route

If you prefer Terraform, follow `terraform/README.md` instead of Steps 1-10. The result is the same.
