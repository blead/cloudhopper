resource "google_compute_firewall" "allow-inbound" {
  name    = "tf-allow-inbound"
  network = "${google_compute_network.live_migration.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["80", "22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow-internal" {
  name    = "tf-allow-internal"
  network = "${google_compute_network.live_migration.self_link}"

  allow {
    protocol = "all"
  }

  source_ranges = ["${google_compute_subnetwork.live_migration.ip_cidr_range}"]
}

resource "google_compute_firewall" "allow-aws" {
  name    = "tf-allow-aws"
  network = "${google_compute_network.live_migration.self_link}"

  allow {
    protocol = "all"
  }

  source_ranges = ["${aws_vpc.default.cidr_block}"]
}

resource "google_compute_firewall" "allow-aws-vpn" {
  name    = "tf-allow-aws-vpn"
  network = "${google_compute_network.live_migration.self_link}"

  allow {
    protocol = "all"
  }

  source_ranges = ["${aws_instance.vpn.public_ip}/32"]
}

resource "google_compute_firewall" "allow-egress" {
  name    = "tf-allow-egress"
  direction = "EGRESS"
  network = "${google_compute_network.live_migration.self_link}"

  allow {
    protocol = "all"
  }

}
