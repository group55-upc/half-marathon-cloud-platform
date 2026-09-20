terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "half-marathon-cloud-platform"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# ============================================================
# DYNAMODB TABLE
# ============================================================

resource "aws_dynamodb_table" "races" {
  name         = "${var.project_name}-races-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Mantingut desactivat inicialment per reduir costos.
  point_in_time_recovery {
    enabled = false
  }

  # Xifrat amb la clau gestionada per AWS.
  server_side_encryption {
    enabled = true
  }

  deletion_protection_enabled = false

  tags = {
    Name = "${var.project_name}-races-${var.environment}"
  }
}

# ============================================================
# INITIAL SEED DATA
# ============================================================

locals {
  races = {
    "race-001" = {
      name     = "Mitja Marató de Barcelona"
      city     = "Barcelona"
      country  = "Spain"
      date     = "2027-02-14"
      distance = 21.097
      web      = "https://www.mitjamarato.barcelona"
      source   = "manual-seed"
    }

    "race-002" = {
      name     = "Movistar Madrid Medio Maratón"
      city     = "Madrid"
      country  = "Spain"
      date     = "2027-04-04"
      distance = 21.097
      web      = "https://www.movistarmadridmediomaraton.es"
      source   = "manual-seed"
    }

    "race-003" = {
      name     = "Lisbon Half Marathon"
      city     = "Lisbon"
      country  = "Portugal"
      date     = "2027-03-14"
      distance = 21.097
      web      = "https://www.maratonaclubedeportugal.com"
      source   = "manual-seed"
    }

    "race-004" = {
      name     = "Berlin Half Marathon"
      city     = "Berlin"
      country  = "Germany"
      date     = "2027-04-11"
      distance = 21.097
      web      = "https://www.generali-berliner-halbmarathon.de"
      source   = "manual-seed"
    }

    "race-005" = {
      name     = "Paris Half Marathon"
      city     = "Paris"
      country  = "France"
      date     = "2027-03-07"
      distance = 21.097
      web      = "https://www.harmoniemutuelle-semideparis.com"
      source   = "manual-seed"
    }

    "race-006" = {
      name     = "Prague Half Marathon"
      city     = "Prague"
      country  = "Czech Republic"
      date     = "2027-04-10"
      distance = 21.097
      web      = "https://www.runczech.com"
      source   = "manual-seed"
    }

    "race-007" = {
      name     = "Copenhagen Half Marathon"
      city     = "Copenhagen"
      country  = "Denmark"
      date     = "2027-09-19"
      distance = 21.097
      web      = "https://cphhalf.dk"
      source   = "manual-seed"
    }

    "race-008" = {
      name     = "Valencia Half Marathon"
      city     = "Valencia"
      country  = "Spain"
      date     = "2027-10-24"
      distance = 21.097
      web      = "https://www.valenciahalf.com"
      source   = "manual-seed"
    }

    "race-009" = {
      name     = "United Airlines NYC Half"
      city     = "New York"
      country  = "United States"
      date     = "2027-03-21"
      distance = 21.097
      web      = "https://www.nyrr.org"
      source   = "manual-seed"
    }

    "race-010" = {
      name     = "London Landmarks Half Marathon"
      city     = "London"
      country  = "United Kingdom"
      date     = "2027-04-11"
      distance = 21.097
      web      = "https://llhm.co.uk"
      source   = "manual-seed"
    }
  }
}

resource "aws_dynamodb_table_item" "race_seed" {
  for_each = local.races

  table_name = aws_dynamodb_table.races.name
  hash_key   = aws_dynamodb_table.races.hash_key

  item = jsonencode({
    id = {
      S = each.key
    }

    name = {
      S = each.value.name
    }

    city = {
      S = each.value.city
    }

    country = {
      S = each.value.country
    }

    date = {
      S = each.value.date
    }

    distance = {
      N = tostring(each.value.distance)
    }

    web = {
      S = each.value.web
    }

    source = {
      S = each.value.source
    }

    last_update = {
      S = "2026-07-12"
    }
  })

  depends_on = [
    aws_dynamodb_table.races
  ]
}
