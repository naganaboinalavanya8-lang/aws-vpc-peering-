output "peering_connection_id" {
  value = aws_vpc_peering_connection.a_to_b.id
}

output "a_public_instance_id" {
  value = aws_instance.a_public.id
}

output "a_public_private_ip" {
  value = aws_instance.a_public.private_ip
}

output "a_public_public_ip" {
  description = "Open http://<this>:8080 from the allowed IP to see the public page."
  value       = aws_instance.a_public.public_ip
}

output "a_private_instance_id" {
  value = aws_instance.a_private.id
}

output "a_private_private_ip" {
  value = aws_instance.a_private.private_ip
}

output "b_private_instance_id" {
  value = aws_instance.b_private.id
}

output "b_private_private_ip" {
  value = aws_instance.b_private.private_ip
}

output "connect_commands" {
  description = "AWS CLI commands to open a shell (needs AWS CLI v2 and permission to use the endpoints). You can also use the Console 'Connect' button."
  value = {
    a_public  = "aws ec2-instance-connect ssh --instance-id ${aws_instance.a_public.id} --connection-type eice"
    a_private = "aws ec2-instance-connect ssh --instance-id ${aws_instance.a_private.id} --connection-type eice"
    b_private = "aws ec2-instance-connect ssh --instance-id ${aws_instance.b_private.id} --connection-type eice"
  }
}
