# Latest Amazon Linux 2023 AMI, looked up from AWS's public SSM parameter.
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  ami_id = data.aws_ssm_parameter.al2023.value
}

# ---------------------------------------------------------------- Instances
# No key pair is attached on purpose: you connect with EC2 Instance Connect
# Endpoint, which pushes a short-lived key. So there is no .pem file to leak.

resource "aws_instance" "a_public" {
  ami                         = local.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.a_public.id
  vpc_security_group_ids      = [aws_security_group.a_public.id]
  associate_public_ip_address = true # the ONLY instance with a public IP

  user_data = templatefile("${path.module}/../config/user-data.sh.tpl", {
    server_name = "a-public"
  })
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # IMDSv2 only
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  tags = { Name = "${var.project_name}-a-public" }
}

resource "aws_instance" "a_private" {
  ami                         = local.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.a_private.id
  vpc_security_group_ids      = [aws_security_group.a_private.id]
  associate_public_ip_address = false

  user_data = templatefile("${path.module}/../config/user-data.sh.tpl", {
    server_name = "a-private"
  })
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  tags = { Name = "${var.project_name}-a-private" }
}

resource "aws_instance" "b_private" {
  ami                         = local.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.b_private.id
  vpc_security_group_ids      = [aws_security_group.b_private.id]
  associate_public_ip_address = false

  user_data = templatefile("${path.module}/../config/user-data.sh.tpl", {
    server_name = "b-private"
  })
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  tags = { Name = "${var.project_name}-b-private" }
}

# ------------------------------------------- EC2 Instance Connect Endpoints
# One per VPC (an endpoint can only reach instances in its OWN VPC; it cannot
# hop across the peering connection). Same AZ as the instances so no cross-AZ
# data charge applies.
resource "aws_ec2_instance_connect_endpoint" "a" {
  subnet_id          = aws_subnet.a_private.id
  security_group_ids = [aws_security_group.eice_a.id]
  preserve_client_ip = false

  tags = { Name = "${var.project_name}-eice-a" }
}

resource "aws_ec2_instance_connect_endpoint" "b" {
  subnet_id          = aws_subnet.b_private.id
  security_group_ids = [aws_security_group.eice_b.id]
  preserve_client_ip = false

  tags = { Name = "${var.project_name}-eice-b" }
}
