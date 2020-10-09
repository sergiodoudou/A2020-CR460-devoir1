terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

provider "google" {
  credentials = file("cr460a2020-35b49c31d56e.json")
  project     = var.project
  region      = var.region
  zone        = var.zone
}

resource "google_compute_instance" "canard" {
  name         = "canard"
  machine_type = "f1-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.prod-dmz.name

    access_config {
      // Ephemeral IPS give an  external ip
    }
  }

  metadata_startup_script = "apt-get -y update && apt-get -y upgrade && apt-get -y install apache2 && systemctl start apache2"

}

resource "google_compute_instance" "mouton" {
  name         = "mouton"
  machine_type = "f1-micro"
  zone         = var.zone

  tags = ["interne"]

  boot_disk {
    initialize_params {
      image = "fedora-coreos-cloud/fedora-coreos-stable"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.prod-interne.name

    access_config {
      // Ephemeral IPS give an  external ip
    }
  }

}

resource "google_compute_instance" "cheval" {
  name         = "cheval"
  machine_type = "f1-micro"
  zone         = var.zone

  tags = ["traitement"]

  boot_disk {
    initialize_params {
      image = "fedora-coreos-cloud/fedora-coreos-stable"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.prod-traitement.name

    access_config {
      // Ephemeral IPS give an  external ip
    }
  }
}

resource "google_compute_instance" "fermier" {
  name         = "fermier"
  machine_type = "f1-micro"
  zone         = var.zone

  tags = ["fermier"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = google_compute_network.devoir1.id

  }
}

resource "google_compute_network" "devoir1" {
  name = "devoir1"
}

resource "google_compute_subnetwork" "prod-interne" {
  name          = "prod-interne"
  ip_cidr_range = "10.0.3.0/24"
  region        = var.region
  network       = google_compute_network.devoir1.id
}

resource "google_compute_subnetwork" "prod-dmz" {
  name          = "prod-dmz"
  ip_cidr_range = "172.16.3.0/24"
  region        = var.region
  network       = google_compute_network.devoir1.id
}

resource "google_compute_subnetwork" "prod-traitement" {
  name          = "prod-traitement"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.devoir1.id
}


resource "google_compute_firewall" "traitement" {
  name = "traitement"
  allow {
    protocol = "TCP"
    ports    = ["2846", "5462"]
  }
  source_ranges = ["10.0.0.0/24"]
  network       = google_compute_network.devoir1.name
}

resource "google_compute_firewall" "traficssh" {
  name = "traficssh"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags = ["interne"]
  network     = google_compute_network.devoir1.name
}

resource "google_compute_firewall" "traficweb" {
  name = "traficweb"
  allow {
    ports    = ["80", "443"]
    protocol = "tcp"
  }
  network     = google_compute_network.devoir1.name
  target_tags = ["public"]
}
