# 09. Technical Interview Questions and Answers

Answers are in simple English. Practise saying them out loud in your own words.

**1. What is a VPC?**
A private network that belongs to my AWS account. I choose its IP range, subnets, routes and firewalls. Nobody else can see inside it unless I connect it.

**2. What does `10.0.0.0/16` mean?**
It is a block of IP addresses. The `/16` means the first 16 bits are fixed, so there are 2^16 = 65,536 addresses, from `10.0.0.0` to `10.0.255.255`.

**3. What makes a subnet public or private?**
Its route table. If the route table has `0.0.0.0/0` pointing to an Internet Gateway, the subnet is public. If it does not, the subnet is private. A public IP on the instance is also needed for internet access.

**4. What is VPC peering?**
A private, one-to-one connection between two VPCs. Instances use private IPs and traffic stays on the AWS network. It works within a Region, across Regions, and across accounts.

**5. What are the steps to set up peering?**
Request from the requester VPC, accept in the accepter VPC, add routes in both VPCs' route tables, then allow the traffic in the security groups (and NACLs if changed).

**6. Why can't two VPCs with overlapping CIDRs be peered?**
AWS could not tell which VPC an address belongs to, so routing would be ambiguous. Peering is refused.

**7. Why is VPC peering not transitive?**
A peering link works only between its two VPCs. If A-B and B-C are peered, A cannot reach C through B. A needs its own link to C. The same rule means B cannot use A's Internet Gateway; I showed this in test T7.

**8. What is the alternative when you have many VPCs?**
AWS Transit Gateway. It is a hub that all VPCs attach to, so routing between them is possible without a link for every pair.

**9. Why must routes be added on both sides?**
Traffic needs a path out and a path back. If only the source VPC has the route, the destination receives the request but has no route to answer.

**10. What is the difference between an Internet Gateway and a NAT Gateway?**
An Internet Gateway gives two-way internet access to resources with public IPs. A NAT Gateway lets private resources start outbound connections while blocking inbound connections from the internet. NAT has hourly and per-GB charges.

**11. Did your design need a NAT Gateway? Why not?**
No. The private instances only talk to each other and to the admin through the endpoint. Their web page uses software already installed, so they download nothing. Leaving NAT out saves cost and keeps them isolated.

**12. How did you access private instances without exposing SSH?**
EC2 Instance Connect Endpoint. AWS checks my IAM permissions, pushes a temporary key to the instance, and the endpoint inside the VPC forwards my SSH session. Port 22 is only open to the endpoint's security group, never to the internet.

**13. Why did you need two endpoints?**
An endpoint can only reach instances in its own VPC and does not work across peering. One per VPC.

**14. How else could you reach private instances?**
A bastion host (more to secure and pay for), or Systems Manager Session Manager (no inbound ports, but needs an IAM role, the agent, and NAT or VPC endpoints).

**15. What is the difference between a security group and a network ACL?**
A security group is attached to an instance, is stateful, and only has allow rules. A network ACL is attached to a subnet, is stateless, and has allow and deny rules.

**16. What does "stateful" mean?**
If a request is allowed in, the reply is allowed out automatically; I do not write a rule for the reply.

**17. Why did you change the diagram's `28.x.x.x` ranges?**
They do not overlap each other so peering would work, but they are public internet address space, not RFC 1918 private space. Packets to a real `28.x` host would be routed into my own VPC. Private ranges are best practice.

**18. How many usable IPs are in a /24 subnet in AWS?**
251. AWS reserves five addresses: network address, VPC router, DNS, one for future use, and the last (broadcast) address.

**19. What costs money in your design?**
EC2 instances, EBS volumes, and the public IPv4 address. Peering creation is free; peering traffic in the same AZ is free, cross-AZ is charged. I used one AZ and cleaned up the same day.

**20. Why one Availability Zone? Is that a weakness?**
It avoids cross-AZ data charges. Yes, it is a weakness for availability: an AZ failure would take the lab down. For a production design I would use at least two AZs (Project 2 does).

**21. How would you troubleshoot "ping between VPCs fails"?**
(1) Peering status Active? (2) Routes on both sides, not blackholed? (3) CIDRs overlapping? (4) Security group allows ICMP from the source CIDR? (5) The instance is running? I can also use VPC Reachability Analyzer.

**22. A request times out vs "connection refused": what is the difference?**
Timed out: something drops the packets (route or firewall). Refused: the packet reached the machine but nothing listens on that port.

**23. What security hardening did you apply to the instances?**
No key pair or public SSH, IMDSv2 required, encrypted volumes, a single `/32` source for the public test page, security-group references for SSH.

**24. What would you add to make this production-ready?**
Two or more AZs, NAT per AZ or VPC endpoints, Session Manager, VPC Flow Logs, GuardDuty, narrower routes and outbound rules, Transit Gateway if more VPCs join, infrastructure as code with remote state.

**25. How would you peer VPCs in two different accounts?**
The requester specifies the other account ID and VPC ID; the other account's owner accepts the request. Both accounts add routes. CIDRs still must not overlap.
