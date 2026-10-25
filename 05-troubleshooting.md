# 05. Troubleshooting Guide

Work **from the outside in**: peering → routes → security groups → the instance itself.

## Quick decision tree

1. Is the **peering status Active**? If not → section A.
2. Does **each route table** (both sides) have the route to the other CIDR via `pcx-…`? If not → section B.
3. Do the **CIDRs overlap**? → section C.
4. Does the destination **security group** allow your protocol from your source? → section D.
5. Is the **web service running** on the target? → section E.
6. Can you **connect** to the instance in the first place? → section F.

## A. Peering connection problems

| Symptom | Cause | Fix |
|---|---|---|
| Status **Pending acceptance** | Nobody accepted the request | Select it → Actions → **Accept request** |
| Status **Failed** or **Rejected** | CIDRs overlap, or the accepter rejected | Check section C; delete and re-create |
| Status **Expired** | Request was not accepted within the time limit | Delete and create it again |
| "Cannot create peering" error | Overlapping CIDRs, or a peering already exists between the same two VPCs | Fix addressing; only one connection per VPC pair |

## B. Missing or wrong routes

| Symptom | Cause | Fix |
|---|---|---|
| Both ping and HTTP time out | No peering route on the **source** side | Add `<other VPC CIDR> → pcx-…` to the source subnet's route table |
| Request arrives, reply never returns | No peering route on the **destination** side (the return route) | Add the reverse route. Remember: **both** directions are needed |
| Route shows **Blackhole** | The peering connection was deleted or is not Active | Re-create/accept the peering, then update the route target |
| Route added to the wrong table | The subnet is associated with a different route table | VPC → Subnets → select subnet → **Route table** tab; confirm which table it uses, and add the route there |
| Route added to the *main* table, nothing changes | The subnet has an explicit association to another table | Same as above |
| Private subnet unexpectedly has internet | Someone added `0.0.0.0/0` to its table | Remove it (this design has no NAT) |

## C. Incorrect or overlapping CIDRs

| Symptom | Cause | Fix |
|---|---|---|
| Peering fails with an overlap error | VPC A and B ranges overlap (e.g. both `10.0.0.0/16`) | VPC CIDRs cannot be changed freely. Create a new VPC with a non-overlapping range and move resources |
| Route destination does not match the target IP | Typo, e.g. `10.1.0.0/24` instead of `10.1.0.0/16` | Edit the route so the destination covers the target subnet |
| Subnet creation fails | Subnet CIDR is outside the VPC range or overlaps another subnet | Check against the table in `02-design.md` |

Quick offline check of your own plan: edit `config/network-plan.json`, then run `python3 -m unittest discover -s tests -v`.

## D. Security-group restrictions

| Symptom | Cause | Fix |
|---|---|---|
| ping fails, HTTP works | No ICMP rule | Add **All ICMP - IPv4** inbound from the source CIDR |
| HTTP fails, ping works | No TCP 8080 rule | Add **Custom TCP 8080** inbound from the source CIDR |
| Browser to public IP times out | Your IP changed (home/mobile networks change IPs), or you used a different network | Update the SG rule to your current IP (`/32`) |
| Instance Connect Endpoint cannot reach SSH | Instance SG does not allow SSH from the endpoint SG, or the endpoint SG blocks outbound 22 | Check both rules (section F) |

Remember: security groups are **stateful**. You never need an inbound rule for replies.

## E. The instance itself

Run these inside the instance:

```bash
sudo systemctl status lab-web.service   # should say "active (running)"
curl -s http://localhost:8080/          # should print the HTML page
sudo cat /var/log/cloud-init-output.log | tail -30   # shows errors from the start-up script
```

| Symptom | Cause | Fix |
|---|---|---|
| Service not found | User data did not run (typo, or you edited it after launch: user data runs only on first boot) | Terminate and re-launch with correct user data, or create the service by hand |
| Page says `Hello from unnamed-edit-me` | You pasted the template without editing the `SERVER_NAME=` line | Re-launch with the line edited, or fix `/opt/web/index.html` by hand |
| `ping` command not found | Minimal image | Test with `curl` instead |

## F. You cannot open a shell

| Symptom | Cause | Fix |
|---|---|---|
| "Connect using EC2 Instance Connect Endpoint" is greyed out | No endpoint in that VPC, or still **Creating** | VPC → Endpoints; wait for **Available** |
| Connection fails right away | Missing IAM permission | See `config/iam-policy-eice-user-example.json` or ask your account admin |
| Connection times out | Endpoint SG outbound 22 is wrong, or instance SG does not allow the endpoint SG | Fix both rules |
| Works for `a-private`, not `b-private` | Endpoints only reach their **own** VPC. You need endpoint B in VPC B | Create `peering-lab-eice-b` |
| You tried to use endpoint A to reach VPC B | Not supported (does not cross peering) | Use endpoint B |
| Console says the instance is not eligible | Wrong username, or the OS lacks EC2 Instance Connect | Use `ec2-user` on Amazon Linux 2023 |

## G. "It worked yesterday"

| Cause | Fix |
|---|---|
| Your public IP changed (T3/T9) | Update the SG rule |
| Instance was stopped/started and the public IP changed | Read the new public IP in the Console (only the Elastic IP type is permanent) |
| Someone changed a route or SG | Compare with `02-design.md` |

## H. Useful AWS tool (optional)

**VPC Reachability Analyzer** (VPC console → Reachability Analyzer) can trace a path between two resources and tell you which route or rule blocks it. Check the pricing page first: it charges per analysis run.
