"""Offline checks for the VPC peering network plan.

These tests need NO AWS account. They only read config/network-plan.json and
check the design rules that AWS enforces (or that good practice requires).

Run from the project root:
    python3 -m unittest discover -s tests -v
"""
import ipaddress
import json
import unittest
from pathlib import Path

PLAN_PATH = Path(__file__).resolve().parent.parent / "config" / "network-plan.json"

# RFC 1918 private ranges
RFC1918 = [
    ipaddress.ip_network("10.0.0.0/8"),
    ipaddress.ip_network("172.16.0.0/12"),
    ipaddress.ip_network("192.168.0.0/16"),
]


def load_plan():
    with open(PLAN_PATH, encoding="utf-8") as f:
        return json.load(f)


def is_rfc1918(net):
    return any(net.subnet_of(private) for private in RFC1918)


class NetworkPlanTests(unittest.TestCase):
    def setUp(self):
        self.plan = load_plan()
        self.vpcs = self.plan["vpcs"]

    def test_vpc_cidrs_are_rfc1918(self):
        for name, vpc in self.vpcs.items():
            net = ipaddress.ip_network(vpc["cidr"])
            self.assertTrue(is_rfc1918(net), f"{name} {net} is not RFC 1918")

    def test_vpc_cidrs_do_not_overlap(self):
        # AWS refuses to peer VPCs whose CIDR blocks overlap.
        nets = {n: ipaddress.ip_network(v["cidr"]) for n, v in self.vpcs.items()}
        names = list(nets)
        for i, a in enumerate(names):
            for b in names[i + 1:]:
                self.assertFalse(nets[a].overlaps(nets[b]), f"{a} overlaps {b}")

    def test_vpc_size_is_allowed_by_aws(self):
        # AWS VPC CIDR blocks must be between /16 and /28.
        for name, vpc in self.vpcs.items():
            prefix = ipaddress.ip_network(vpc["cidr"]).prefixlen
            self.assertTrue(16 <= prefix <= 28, f"{name} /{prefix} not in /16../28")

    def test_subnets_are_inside_their_vpc_and_do_not_overlap(self):
        for name, vpc in self.vpcs.items():
            vpc_net = ipaddress.ip_network(vpc["cidr"])
            subnets = {s: ipaddress.ip_network(d["cidr"]) for s, d in vpc["subnets"].items()}
            for s, net in subnets.items():
                self.assertTrue(net.subnet_of(vpc_net), f"{s} not inside {name}")
            items = list(subnets.items())
            for i, (s1, n1) in enumerate(items):
                for s2, n2 in items[i + 1:]:
                    self.assertFalse(n1.overlaps(n2), f"{s1} overlaps {s2}")

    def test_every_subnet_has_exactly_one_route_table(self):
        for name, vpc in self.vpcs.items():
            seen = []
            for rt in vpc["route_tables"].values():
                seen.extend(rt["associated_subnets"])
            self.assertCountEqual(seen, list(vpc["subnets"]), f"{name}: subnet/RT mismatch")

    def test_every_route_table_has_the_local_route(self):
        for name, vpc in self.vpcs.items():
            for rt_name, rt in vpc["route_tables"].items():
                local = [r for r in rt["routes"] if r["target"] == "local"]
                self.assertEqual(len(local), 1, f"{rt_name} needs one local route")
                self.assertEqual(local[0]["destination"], vpc["cidr"])

    def test_peering_routes_point_at_the_other_vpc(self):
        cidrs = {n: v["cidr"] for n, v in self.vpcs.items()}
        for name, vpc in self.vpcs.items():
            other = [c for n, c in cidrs.items() if n != name][0]
            for rt_name, rt in vpc["route_tables"].items():
                dests = [r["destination"] for r in rt["routes"] if r["target"] == "pcx"]
                self.assertEqual(dests, [other], f"{rt_name} needs a pcx route to {other}")

    def test_private_subnets_have_no_default_route(self):
        # No NAT gateway in this design, so private subnets must not route 0.0.0.0/0.
        for vpc in self.vpcs.values():
            for rt in vpc["route_tables"].values():
                for sn in rt["associated_subnets"]:
                    if vpc["subnets"][sn]["type"] == "private":
                        dests = [r["destination"] for r in rt["routes"]]
                        self.assertNotIn("0.0.0.0/0", dests, f"{sn} must stay private")

    def test_only_public_subnets_route_to_the_internet_gateway(self):
        for vpc in self.vpcs.values():
            for rt in vpc["route_tables"].values():
                has_igw = any(r["target"] == "igw" for r in rt["routes"])
                types = {vpc["subnets"][s]["type"] for s in rt["associated_subnets"]}
                if has_igw:
                    self.assertEqual(types, {"public"})

    def test_original_diagram_ranges_do_not_overlap_each_other(self):
        # The diagram's own ranges are valid for peering, but they are NOT private space.
        d = self.plan["original_diagram"]
        n1 = ipaddress.ip_network(d["vpc1_cidr"])
        n2 = ipaddress.ip_network(d["vpc2_cidr"])
        self.assertFalse(n1.overlaps(n2))
        self.assertFalse(is_rfc1918(n1))
        self.assertFalse(is_rfc1918(n2))


if __name__ == "__main__":
    unittest.main()
