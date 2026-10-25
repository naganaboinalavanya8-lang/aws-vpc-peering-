# Security groups are virtual firewalls attached to instances. They are "stateful":
# if a request is allowed in, the reply is allowed out automatically.
# Outbound rules are left at the default (allow all) for the instances, because
# the interesting restrictions in this lab are on INBOUND traffic.

# ------------------------------------------------ EC2 Instance Connect Endpoints
# The endpoint lets YOU open SSH to a private instance with no public IP and no
# bastion host. Its own security group allows NO inbound traffic; it only needs
# to send SSH (port 22) to the instances in its own VPC.
resource "aws_security_group" "eice_a" {
  name        = "${var.project_name}-eice-a"
  description = "EC2 Instance Connect Endpoint in VPC A"
  vpc_id      = aws_vpc.a.id

  egress {
    description = "SSH to instances in VPC A only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_a_cidr]
  }

  tags = { Name = "${var.project_name}-eice-a-sg" }
}

resource "aws_security_group" "eice_b" {
  name        = "${var.project_name}-eice-b"
  description = "EC2 Instance Connect Endpoint in VPC B"
  vpc_id      = aws_vpc.b.id

  egress {
    description = "SSH to instances in VPC B only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_b_cidr]
  }

  tags = { Name = "${var.project_name}-eice-b-sg" }
}

# ------------------------------------------------ Instance: A public
resource "aws_security_group" "a_public" {
  name        = "${var.project_name}-a-public"
  description = "Public instance in VPC A"
  vpc_id      = aws_vpc.a.id

  tags = { Name = "${var.project_name}-a-public-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "a_public_web_from_me" {
  security_group_id = aws_security_group.a_public.id
  description       = "Web test page from my IP only"
  ip_protocol       = "tcp"
  from_port         = 8080
  to_port           = 8080
  cidr_ipv4         = var.allowed_web_cidr
}

resource "aws_vpc_security_group_ingress_rule" "a_public_ssh_from_eice" {
  security_group_id            = aws_security_group.a_public.id
  description                  = "SSH from the Instance Connect Endpoint only"
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  referenced_security_group_id = aws_security_group.eice_a.id
}

resource "aws_vpc_security_group_ingress_rule" "a_public_icmp_from_b" {
  security_group_id = aws_security_group.a_public.id
  description       = "Ping from VPC B (through the peering connection)"
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = var.vpc_b_cidr
}

resource "aws_vpc_security_group_ingress_rule" "a_public_web_from_b" {
  security_group_id = aws_security_group.a_public.id
  description       = "Test page from VPC B"
  ip_protocol       = "tcp"
  from_port         = 8080
  to_port           = 8080
  cidr_ipv4         = var.vpc_b_cidr
}

resource "aws_vpc_security_group_egress_rule" "a_public_all_out" {
  security_group_id = aws_security_group.a_public.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ------------------------------------------------ Instance: A private
resource "aws_security_group" "a_private" {
  name        = "${var.project_name}-a-private"
  description = "Private instance in VPC A"
  vpc_id      = aws_vpc.a.id

  tags = { Name = "${var.project_name}-a-private-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "a_private_ssh_from_eice" {
  security_group_id            = aws_security_group.a_private.id
  description                  = "SSH from the Instance Connect Endpoint only"
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  referenced_security_group_id = aws_security_group.eice_a.id
}

resource "aws_vpc_security_group_ingress_rule" "a_private_icmp_from_vpcs" {
  for_each = {
    vpc_a = var.vpc_a_cidr
    vpc_b = var.vpc_b_cidr
  }

  security_group_id = aws_security_group.a_private.id
  description       = "Ping from ${each.key}"
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "a_private_web_from_vpcs" {
  for_each = {
    vpc_a = var.vpc_a_cidr
    vpc_b = var.vpc_b_cidr
  }

  security_group_id = aws_security_group.a_private.id
  description       = "Test page from ${each.key}"
  ip_protocol       = "tcp"
  from_port         = 8080
  to_port           = 8080
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "a_private_all_out" {
  security_group_id = aws_security_group.a_private.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ------------------------------------------------ Instance: B private
resource "aws_security_group" "b_private" {
  name        = "${var.project_name}-b-private"
  description = "Private instance in VPC B"
  vpc_id      = aws_vpc.b.id

  tags = { Name = "${var.project_name}-b-private-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "b_private_ssh_from_eice" {
  security_group_id            = aws_security_group.b_private.id
  description                  = "SSH from the Instance Connect Endpoint only"
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  referenced_security_group_id = aws_security_group.eice_b.id
}

resource "aws_vpc_security_group_ingress_rule" "b_private_icmp_from_a" {
  security_group_id = aws_security_group.b_private.id
  description       = "Ping from VPC A (through the peering connection)"
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = var.vpc_a_cidr
}

resource "aws_vpc_security_group_ingress_rule" "b_private_web_from_a" {
  security_group_id = aws_security_group.b_private.id
  description       = "Test page from VPC A"
  ip_protocol       = "tcp"
  from_port         = 8080
  to_port           = 8080
  cidr_ipv4         = var.vpc_a_cidr
}

resource "aws_vpc_security_group_egress_rule" "b_private_all_out" {
  security_group_id = aws_security_group.b_private.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
