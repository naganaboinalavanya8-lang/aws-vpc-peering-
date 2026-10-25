# Project Report: AWS VPC Peering and Secure Network Connectivity

**Author:** *(your name)*  **Programme:** AWS Solutions Architect Associate internship, EWB Courses  **Date:** *(fill in)*

> **Honesty note for the evaluator:** sections marked **[TO COMPLETE AFTER DEPLOYMENT]** are blank until the author has built and tested the design in AWS. The design, code and offline checks are complete. No AWS test result appears in this report unless the author has entered it from a real run.

## 1. Abstract

This project designs and documents a secure network in which two Amazon VPCs are connected with VPC peering. One VPC holds a public and a private subnet and an Internet Gateway; the other holds a private subnet. Three EC2 instances demonstrate traffic between the networks. Administrators reach the private instances through EC2 Instance Connect Endpoints, so no SSH or RDP port is exposed to the internet and no bastion host or NAT gateway is needed. The design uses non-overlapping RFC 1918 address ranges, explicit route tables, and least-privilege security groups. A Terraform configuration and an offline unit-test suite accompany the Console guide. **[TO COMPLETE AFTER DEPLOYMENT: add one sentence stating the measured outcome.]**

## 2. Introduction

Organisations often split workloads across several VPCs (for example by team, environment or account). Those networks are isolated by default. VPC peering lets them exchange traffic over private IP addresses without crossing the public internet. Correct designs depend on three things beginners often get wrong: address planning (no overlaps), routing (routes needed on both sides), and firewalling (security groups).

## 3. Problem Statement

How can two isolated VPCs communicate privately, while keeping private servers unreachable from the internet and still allowing administrators to manage them, at minimal cost?

## 4. Objectives

1. Design two non-overlapping VPCs with an explicit subnet plan.
2. Connect them with a VPC peering connection and the required routes.
3. Expose only what is necessary to the internet (one test page, one source IP).
4. Provide secure administrative access to private instances with no open SSH/RDP.
5. Explain why peering is not transitive and demonstrate it.
6. Provide reproducible deployment (Console and Terraform), tests and cleanup.

## 5. Methodology

1. Study the reference diagram (as described in the course material) and identify the intended traffic flows.
2. Evaluate the diagram's address ranges (`28.0.0.0/16`, `28.200.0.0/16`) and select RFC 1918 ranges (`10.0.0.0/16`, `10.1.0.0/16`).
3. Write the plan as data (`config/network-plan.json`) and verify it with automated tests.
4. Write the Console procedure and a matching Terraform configuration.
5. Define tests with expected results, to be recorded after deployment.
6. Document costs, security decisions and cleanup.

## 6. Architecture

See `diagrams/architecture.mmd` (also in the README).

| Component | Description |
|---|---|
| VPC A `10.0.0.0/16` | Public subnet `10.0.1.0/24`, private subnet `10.0.2.0/24`, Internet Gateway |
| VPC B `10.1.0.0/16` | Private subnet `10.1.1.0/24` |
| Peering connection | A ↔ B, routes in all three route tables |
| EC2 `a-public` | Public IP; test page on TCP 8080, reachable only from the author's IP |
| EC2 `a-private`, `b-private` | No public IP; reachable only through peering or the endpoints |
| EC2 Instance Connect Endpoints (A and B) | Secure shell access, authorised through IAM, one per VPC |

Design decisions and rationale: `docs/02-design.md`.

## 7. Implementation

- Console procedure: `docs/03-console-deployment-guide.md`.
- Terraform: `terraform/` (8 files; variables for every address).
- Instance start-up: `config/user-data.sh.tpl` starts a tiny Python web server, so private instances need no internet.
- **[TO COMPLETE AFTER DEPLOYMENT]** which route (Console or Terraform) was used, Region, AZ, instance type, date.

## 8. Testing

Test plan T1-T10 (and optional break-it tests B1-B3) is in `docs/04-testing.md`.

**Offline checks completed in the build environment (no AWS used):**

| Check | Outcome |
|---|---|
| 10 unit tests on the network plan | All passed |
| Shell syntax of test script and start-up script | OK |
| Terraform formatting, syntax and reference check | OK |
| Full `terraform validate` with the AWS provider | **Not run** (provider registry unreachable in the build sandbox) |

## 9. Results

**[TO COMPLETE AFTER DEPLOYMENT]**

Expected results (not yet observed):

- Peering status Active; all peering routes present.
- Instances in VPC A and VPC B reach each other by ping and HTTP on port 8080.
- Only `a-public` can reach the internet; `b-private` cannot, even though VPC A has an Internet Gateway (non-transitivity).
- Direct SSH to the public IP times out.

Paste your real outputs and screenshot references here.

## 10. Conclusion

**[TO COMPLETE AFTER DEPLOYMENT.]** Suggested points once you have real results: what worked first time, what you had to debug, and how the observed behaviour matched the design.

## 11. Security and cost summary

- No inbound SSH from the internet; SSH only from endpoint security groups.
- No stored keys (no key pair), IMDSv2 enforced, encrypted EBS volumes.
- Test page restricted to a single `/32` address.
- No NAT gateway; one public IPv4 address; one AZ; cleanup within hours.

## 12. Limitations and future work

- Single AZ: no resilience to AZ failure.
- Private instances cannot install updates (no NAT/VPC endpoints).
- Security-group peer rules use whole CIDRs, not individual subnets.
- Not tested with cross-account or cross-Region peering.
- Future: VPC Flow Logs, Session Manager, Transit Gateway for more VPCs (see `07-production-option.md`).

## 13. References (official AWS documentation)

Check each link opens before you submit. Titles are given so you can also search for them.

1. Amazon VPC Peering guide: https://docs.aws.amazon.com/vpc/latest/peering/
2. "What is VPC peering?": https://docs.aws.amazon.com/vpc/latest/peering/what-is-vpc-peering.html
3. Connect using EC2 Instance Connect Endpoint: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connect-with-ec2-instance-connect-endpoint.html
4. Amazon VPC pricing: https://aws.amazon.com/vpc/pricing/
5. Amazon EC2 pricing: https://aws.amazon.com/ec2/pricing/
6. "Demystifying Amazon VPC peering charges" (AWS Networking blog): https://aws.amazon.com/blogs/networking-and-content-delivery/demystifying-amazon-vpc-peering-charges/
7. Amazon VPC User Guide: https://docs.aws.amazon.com/vpc/latest/userguide/
8. Terraform AWS provider documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
