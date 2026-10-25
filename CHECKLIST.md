# Screenshot Checklist (YOU must capture these)

**Status: no screenshots exist yet.** I cannot access AWS or take screenshots. Every item below is for you to capture from your own deployment. Do not use images from the internet or from other people's labs.

## Rules

- Save into this `screenshots/` folder using the exact filenames below.
- **Hide before saving:** your 12-digit **AWS account ID**, email address, access keys, and any IP addresses you do not want public (your home IP in the security group, for example). Use a rectangle/blur in an image editor. Do not just crop if the ID appears elsewhere on the page.
- Include the **Region** selector and the page title where possible, so the screenshot proves context.
- Take screenshots **while the resources exist**. After cleanup, you cannot re-take them.
- Tick the box only after the file is saved.

## List

| ✔ | Filename | Console page | What it must show |
|---|---|---|---|
| ☐ | `01-vpc-a-and-b-overview.png` | VPC → Your VPCs | Both VPCs: names, IPv4 CIDRs `10.0.0.0/16` and `10.1.0.0/16`, State = Available |
| ☐ | `02-subnets.png` | VPC → Subnets (filter by `peering-lab`) | Three subnets with VPC, CIDR (`10.0.1.0/24`, `10.0.2.0/24`, `10.1.1.0/24`), same AZ |
| ☐ | `02b-igw-attached.png` | VPC → Internet gateways | `peering-lab-a-igw` State = **Attached** to `peering-lab-vpc-a` |
| ☐ | `03-security-group-rules.png` | EC2 → Security Groups → inbound rules | Inbound rules for `peering-lab-a-private` and `peering-lab-b-private`; **no `0.0.0.0/0` on port 22** |
| ☐ | `04-ec2-instances.png` | EC2 → Instances | Three instances running; private IPv4 shown; **only `a-public` has a public IPv4** |
| ☐ | `05-peering-active.png` | VPC → Peering connections → details | Status **Active**, requester and accepter VPC IDs and CIDRs |
| ☐ | `06a-a-public-routes.png` | VPC → Route tables → `a-public-rt` → Routes | `local`, `0.0.0.0/0 → igw-…`, `10.1.0.0/16 → pcx-…` (Active) |
| ☐ | `06b-a-private-routes.png` | `a-private-rt` → Routes | `local` and `10.1.0.0/16 → pcx-…`; **no `0.0.0.0/0`** |
| ☐ | `06c-b-private-routes.png` | `b-private-rt` → Routes | `local` and `10.0.0.0/16 → pcx-…` |
| ☐ | `07-eice-available.png` | VPC → Endpoints | Both Instance Connect Endpoints, State **Available** |
| ☐ | `08-test-a-public-to-b-private.png` | Terminal in the Console connect window | Output of `./connectivity-test.sh <b-private IP>` run on `a-public` (test T4) |
| ☐ | `09-test-b-private-to-a.png` | Terminal on `b-private` | Output of the script against `a-private` and `a-public` private IPs (T6) |
| ☐ | `10-internet-check-all-three.png` | Terminals | `--internet` result for each instance: `a-public` OK; `a-private` and `b-private` BLOCKED (T7). Combine three captures into one image if you like |
| ☐ | `11-public-page-from-laptop.png` | Your browser | `http://<public IP>:8080` showing "Hello from a-public" (T3) |
| ☐ | `12-ssh-blocked-from-internet.png` | Your terminal | Direct `ssh` to the public IP timing out (T8) |
| ☐ | `13-cleanup-verified.png` | EC2 Instances, Volumes; VPC list | No lab resources left after cleanup |

## After capturing

1. Update the table in `docs/04-testing.md` with your real **Actual** results and dates.
2. Add the images to the README *Screenshots* section.
3. Re-check every image for account IDs and personal data.
