#!/usr/bin/env bash
# Run this ON an EC2 instance (after connecting with EC2 Instance Connect Endpoint).
# It checks whether this instance can reach other private IPs.
#
# Usage:
#   ./connectivity-test.sh 10.1.1.25                 # test one target
#   ./connectivity-test.sh 10.1.1.25 10.0.2.40       # test several targets
#   ./connectivity-test.sh --internet                # check outbound internet access
#
# For each target it runs:
#   1) ping (ICMP)  - proves the network path and the ICMP security-group rule
#   2) curl port 8080 - proves the path and the TCP 8080 security-group rule
#
# Nothing here changes any AWS resource. It only sends a few test packets.

set -u

pass() { printf '  [PASS] %s\n' "$1"; }
fail() { printf '  [FAIL] %s\n' "$1"; }

test_target() {
  local ip="$1"
  echo "Target: $ip"
  if ping -c 3 -W 2 "$ip" >/dev/null 2>&1; then
    pass "ping $ip"
  else
    fail "ping $ip (no reply: check routes, peering status, ICMP rule)"
  fi
  if body=$(curl -s --max-time 5 "http://$ip:8080/"); then
    pass "http://$ip:8080/ answered"
    # Show only the heading line so the output stays short.
    echo "$body" | grep -i '<h1>' | sed 's/^/        /'
  else
    fail "http://$ip:8080/ (no answer: check routes, peering status, TCP 8080 rule)"
  fi
}

test_internet() {
  echo "Internet check (HTTPS to example.com)"
  if curl -s -o /dev/null --max-time 5 https://example.com; then
    echo "  [OK]      this instance CAN reach the internet"
  else
    echo "  [BLOCKED] this instance can NOT reach the internet"
  fi
  echo "  Expected: a-public = OK. a-private and b-private = BLOCKED (there is no NAT gateway)."
}

if [ "$#" -eq 0 ]; then
  sed -n '2,12p' "$0"
  exit 1
fi

for arg in "$@"; do
  if [ "$arg" = "--internet" ]; then
    test_internet
  else
    test_target "$arg"
  fi
done
