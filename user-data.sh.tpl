#!/bin/bash
# EC2 "user data": a script that runs ONCE as root when the instance first boots.
# It starts a tiny web page on port 8080 so we have something to test with.
#
# It uses only software that is already on Amazon Linux 2023 (python3), so it
# works even on PRIVATE instances that have no internet access (no NAT gateway).
#
# TERRAFORM users: the next line is filled in automatically.
# CONSOLE users: replace the text between the quotes with the instance name,
#                for example: a-public, a-private or b-private.
SERVER_NAME="${server_name}"

set -eu

# If the name above was left empty (Console users who forgot to edit it), use a visible placeholder.
[ -n "$SERVER_NAME" ] || SERVER_NAME="unnamed-edit-me"

# Ask the instance metadata service for our private IP (IMDSv2 = token first).
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)

mkdir -p /opt/web
cat > /opt/web/index.html <<EOF
<!doctype html>
<html><head><title>$SERVER_NAME</title></head>
<body>
<h1>Hello from $SERVER_NAME</h1>
<p>My private IP address is $PRIVATE_IP</p>
</body></html>
EOF

cat > /etc/systemd/system/lab-web.service <<EOF
[Unit]
Description=VPC peering lab web page
After=network.target

[Service]
ExecStart=/usr/bin/python3 -m http.server 8080 --directory /opt/web
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now lab-web.service
