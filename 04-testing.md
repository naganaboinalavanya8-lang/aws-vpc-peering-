# 04. Connectivity Testing

> **Status: NOT YET RUN.** The "Expected" column is what the design should produce. The "Actual" column is **empty on purpose**. Fill it in only after you have run each test yourself. Never write "pass" for a test you did not run.

## What was verified without AWS (done in the build environment)

| Check | Command | Result |
|---|---|---|
| Network plan rules (non-overlap, RFC 1918, subnets inside VPCs, routes, no NAT route on private subnets) | `python3 -m unittest discover -s tests -v` | 10 tests ran, all passed (offline, no AWS involved) |
| Shell script syntax | `bash -n scripts/connectivity-test.sh` | No syntax errors |
| Instance start-up script renders and has valid syntax | rendered with `tofu console`, then `bash -n` | OK |
| Terraform formatting | `tofu fmt -check` | OK |
| Terraform syntax + reference check | HCL parse + custom reference check | All 8 files parse; all 32 references resolve |
| **Full `terraform validate` against the AWS provider** | n/a | **Could not run**: the provider registry is blocked in the build sandbox. Run it yourself (below). |

Run `terraform init && terraform validate` yourself; it needs internet but **no AWS credentials**:

```bash
cd terraform
terraform init -backend=false
terraform validate
```

## Preparation

Have these ready (from the Console, see Step 8 of the deployment guide):

| Item | Value (fill in) |
|---|---|
| `a-public` private IP | |
| `a-public` public IP | |
| `a-private` private IP | |
| `b-private` private IP | |

To run the script on an instance, open a shell with EC2 Instance Connect Endpoint, then create the script. The simplest way: paste the file contents.

```bash
cat > connectivity-test.sh <<'EOF'
# paste the full contents of scripts/connectivity-test.sh here
EOF
chmod +x connectivity-test.sh
```

(The `'EOF'` with quotes stops the shell from changing the text.)

## Test list

| ID | Where you run it | Command / action | Expected result | Actual (you fill in) | Date |
|---|---|---|---|---|---|
| T1 | Console | VPC → Peering connections | `peering-lab-a-to-b` status is **Active** | | |
| T2 | Console | Check the 3 route tables | Each has a route to the other VPC's CIDR via the `pcx-…` target; status **Active** (not "Blackhole") | | |
| T3 | Your laptop browser | Open `http://<a-public public IP>:8080` | Page shows "Hello from a-public" | | |
| T4 | Shell on `a-public` | `./connectivity-test.sh <b-private IP>` | ping **PASS**, HTTP **PASS** ("Hello from b-private") | | |
| T5 | Shell on `a-private` | `./connectivity-test.sh <b-private IP>` | ping **PASS**, HTTP **PASS** | | |
| T6 | Shell on `b-private` | `./connectivity-test.sh <a-private IP> <a-public private IP>` | ping **PASS** and HTTP **PASS** for both | | |
| T7 | Shell on each instance | `./connectivity-test.sh --internet` | `a-public`: **OK**. `a-private`: **BLOCKED**. `b-private`: **BLOCKED** | | |
| T8 | Your laptop | `ssh ec2-user@<a-public public IP>` (or a port scanner on port 22) | **Times out** (no rule allows it). Proves SSH is not exposed. | | |
| T9 | Your laptop | Open `http://<a-public public IP>:8080` from a **different** network (e.g. phone data) | **Times out** (your IP only is allowed) | | |
| T10 | Shell on `a-public` | `./connectivity-test.sh <a-private IP>` | ping **PASS**, HTTP **PASS** (same-VPC path through `local` route) | | |

### Optional break-it tests (learning, then restore!)

| ID | Do this | Expected | Restore |
|---|---|---|---|
| B1 | Delete the route `10.0.0.0/16 → pcx` from `b-private-rt`. Re-run T4. | Requests from A reach B but **replies are lost**: ping and HTTP **FAIL** (timeout) | Re-add the route |
| B2 | Remove ICMP rule from `peering-lab-b-private`. Re-run T4. | ping **FAIL**, HTTP still **PASS** (shows SGs filter per protocol) | Re-add the rule |
| B3 | Remove the TCP 8080 rule from `peering-lab-b-private`. Re-run T4. | ping **PASS**, HTTP **FAIL** | Re-add the rule |

### Why T7 matters (non-transitive peering)

VPC A has an Internet Gateway and VPC B is peered with A. If peering were transitive, `b-private` could "borrow" A's gateway. Expected result: `b-private` is **BLOCKED**, which demonstrates that **peering does not forward traffic to a third network (IGW, VPN, or another VPC).** Also, `b-private` has no route to `0.0.0.0/0` of its own.

## How to read results

| Symptom | Likely meaning |
|---|---|
| ping fails **and** HTTP fails | Routing or peering problem (see troubleshooting) |
| ping fails, HTTP works | ICMP rule missing |
| ping works, HTTP fails | TCP 8080 rule missing, or web service not running |
| "Connection refused" (fast failure) | You reached the machine, but nothing listens on that port |
| "Timed out" (slow failure) | A firewall (security group) or route is dropping packets |

## Recording your evidence

After each test, save a screenshot named as in `screenshots/CHECKLIST.md`. Copy the terminal text into your report's Results section **exactly as it appeared**.
