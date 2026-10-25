# 11. How to Present This Project to an Evaluator (about 5-7 minutes)

Speak in your own words. Only claim what you actually did.

## 1. The problem (30 seconds)

"Two separate networks in AWS cannot talk to each other by default. I built a design where they communicate privately, while the private servers stay hidden from the internet and I can still manage them."

## 2. The architecture (1 minute)

Show the diagram. Point out:
- VPC A (`10.0.0.0/16`): public subnet, private subnet, Internet Gateway.
- VPC B (`10.1.0.0/16`): one private subnet.
- The peering link between them, and the three route tables.

## 3. Three decisions to highlight (2 minutes)

1. **Addresses:** "The reference diagram used `28.x` ranges. They don't overlap, but they are public address space, so I used private RFC 1918 ranges."
2. **Routes:** "Peering needs a route on both sides. Without the return route, replies are lost."
3. **Secure access:** "No SSH is open to the internet. I used EC2 Instance Connect Endpoints, authorised by IAM. There is no key file and no bastion."

## 4. Key concept (1 minute)

"Peering is not transitive. B is peered with A, and A has an Internet Gateway, but B still cannot use it. I tested this with `b-private` and the internet check."

*(Say this only if you ran test T7. If you have not run it yet, say "I expect this and I will test it.")*

## 5. Evidence (1-2 minutes)

Open your screenshots: peering Active, route tables, a successful cross-VPC curl, the blocked internet check.
Say what failed first, if anything, and how you fixed it. Honest debugging stories are valued.

## 6. Cost and cleanup (30 seconds)

"I used three small instances in one AZ, no NAT gateway, finished in one session and deleted everything. Peering within one AZ has no data-transfer charge."

## 7. What I would improve (30 seconds)

Multiple AZs, NAT or VPC endpoints, Session Manager, Flow Logs, Transit Gateway for many VPCs.

## Questions you may get

See `09-interview-questions.md`.
