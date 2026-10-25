# Both VPCs are in the same account and Region, so Terraform can create the request
# AND accept it in one step (auto_accept = true). In the Console you do these as
# two separate steps: "Create peering connection", then "Accept request".
resource "aws_vpc_peering_connection" "a_to_b" {
  vpc_id      = aws_vpc.a.id # requester
  peer_vpc_id = aws_vpc.b.id # accepter
  auto_accept = true

  tags = { Name = "${var.project_name}-a-to-b" }
}

# Peering needs a route in EACH direction. Without both, traffic goes one way
# and the reply gets lost.
resource "aws_route" "a_public_to_b" {
  route_table_id            = aws_route_table.a_public.id
  destination_cidr_block    = var.vpc_b_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.a_to_b.id
}

resource "aws_route" "a_private_to_b" {
  route_table_id            = aws_route_table.a_private.id
  destination_cidr_block    = var.vpc_b_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.a_to_b.id
}

resource "aws_route" "b_private_to_a" {
  route_table_id            = aws_route_table.b_private.id
  destination_cidr_block    = var.vpc_a_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.a_to_b.id
}
