data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  az = var.availability_zone != "" ? var.availability_zone : data.aws_availability_zones.available.names[0]
}

# ---------------------------------------------------------------- VPC A
resource "aws_vpc" "a" {
  cidr_block           = var.vpc_a_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.project_name}-vpc-a" }
}

resource "aws_subnet" "a_public" {
  vpc_id                  = aws_vpc.a.id
  cidr_block              = var.vpc_a_public_subnet_cidr
  availability_zone       = local.az
  map_public_ip_on_launch = false # we ask for a public IP explicitly on the one instance that needs it

  tags = { Name = "${var.project_name}-a-public" }
}

resource "aws_subnet" "a_private" {
  vpc_id            = aws_vpc.a.id
  cidr_block        = var.vpc_a_private_subnet_cidr
  availability_zone = local.az

  tags = { Name = "${var.project_name}-a-private" }
}

resource "aws_internet_gateway" "a" {
  vpc_id = aws_vpc.a.id

  tags = { Name = "${var.project_name}-a-igw" }
}

resource "aws_route_table" "a_public" {
  vpc_id = aws_vpc.a.id

  tags = { Name = "${var.project_name}-a-public-rt" }
}

resource "aws_route_table" "a_private" {
  vpc_id = aws_vpc.a.id

  tags = { Name = "${var.project_name}-a-private-rt" }
}

resource "aws_route_table_association" "a_public" {
  subnet_id      = aws_subnet.a_public.id
  route_table_id = aws_route_table.a_public.id
}

resource "aws_route_table_association" "a_private" {
  subnet_id      = aws_subnet.a_private.id
  route_table_id = aws_route_table.a_private.id
}

# Internet route: ONLY the public route table gets it.
resource "aws_route" "a_public_to_internet" {
  route_table_id         = aws_route_table.a_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.a.id
}

# ---------------------------------------------------------------- VPC B
resource "aws_vpc" "b" {
  cidr_block           = var.vpc_b_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.project_name}-vpc-b" }
}

resource "aws_subnet" "b_private" {
  vpc_id            = aws_vpc.b.id
  cidr_block        = var.vpc_b_private_subnet_cidr
  availability_zone = local.az

  tags = { Name = "${var.project_name}-b-private" }
}

resource "aws_route_table" "b_private" {
  vpc_id = aws_vpc.b.id

  tags = { Name = "${var.project_name}-b-private-rt" }
}

resource "aws_route_table_association" "b_private" {
  subnet_id      = aws_subnet.b_private.id
  route_table_id = aws_route_table.b_private.id
}
