#!/usr/bin/env bash
#
# Ubuntu 26.04 LTS ("Resolute Raccoon") dev/server setup
# Installs: Docker, kubectl, PostgreSQL, MongoDB, Redis, Neo4j (graph DB), Go, Rust
#
# Usage: chmod +x setup-dev-server.sh && ./setup-dev-server.sh
# Run as a regular user with sudo privileges (not as root).

set -euo pipefail

echo "==> Updating system packages"
sudo apt update && sudo apt upgrade -y
sudo apt install -y ca-certificates curl gnupg lsb-release software-properties-common apt-transport-https

# ---------------------------------------------------------------------------
# Docker
# ---------------------------------------------------------------------------
echo "==> Installing Docker"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Let current user run docker without sudo
sudo usermod -aG docker "$USER"

# ---------------------------------------------------------------------------
# kubectl
# ---------------------------------------------------------------------------
echo "==> Installing kubectl"
curl -fsSL -o /tmp/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
rm /tmp/kubectl

# ---------------------------------------------------------------------------
# PostgreSQL (official PGDG repo — gives latest stable, not the older Ubuntu one)
# ---------------------------------------------------------------------------
echo "==> Installing PostgreSQL"
# Ubuntu 26.04 (resolute) is now natively supported by PGDG, so we use the
# real codename via /etc/os-release instead of a hardcoded pin.
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /etc/apt/keyrings/postgresql.gpg
echo "deb [signed-by=/etc/apt/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt $(. /etc/os-release && echo "$VERSION_CODENAME")-pgdg main" | \
  sudo tee /etc/apt/sources.list.d/pgdg.list > /dev/null
sudo apt update
sudo apt install -y postgresql-18 postgresql-client-18 postgresql-contrib

sudo systemctl enable --now postgresql

# ---------------------------------------------------------------------------
# MongoDB
# ---------------------------------------------------------------------------
echo "==> Installing MongoDB"
# MongoDB has not published a native repo for Ubuntu 26.04 "resolute" yet.
# Confirmed current workaround: use the noble (24.04) repo, which works fine
# since MongoDB's packages don't depend on kernel-level specifics.
# Using MongoDB 8.0 (current recommended series; 7.0 is being phased out).
MONGO_UBUNTU_CODENAME="noble"
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg --dearmor -o /etc/apt/keyrings/mongodb.gpg
echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/mongodb.gpg] https://repo.mongodb.org/apt/ubuntu ${MONGO_UBUNTU_CODENAME}/mongodb-org/8.0 multiverse" | \
  sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list > /dev/null
sudo apt update
sudo apt install -y mongodb-org

sudo systemctl enable --now mongod

# ---------------------------------------------------------------------------
# Redis
# ---------------------------------------------------------------------------
echo "==> Installing Redis"
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/redis.gpg
echo "deb [signed-by=/etc/apt/keyrings/redis.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/redis.list > /dev/null
sudo apt update
sudo apt install -y redis

sudo systemctl enable --now redis-server

# ---------------------------------------------------------------------------
# Neo4j (graph DB) — via Docker is usually cleaner, but native option shown too
# ---------------------------------------------------------------------------
echo "==> Installing Neo4j"
curl -fsSL https://debian.neo4j.com/neotechnology.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/neo4j.gpg
echo "deb [signed-by=/etc/apt/keyrings/neo4j.gpg] https://debian.neo4j.com stable latest" | \
  sudo tee /etc/apt/sources.list.d/neo4j.list > /dev/null
sudo apt update
sudo apt install -y neo4j

sudo systemctl enable --now neo4j

# ---------------------------------------------------------------------------
# Go
# ---------------------------------------------------------------------------
echo "==> Installing Go"
GO_VERSION="1.23.4"
curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf /tmp/go.tar.gz
rm /tmp/go.tar.gz
grep -qxF 'export PATH=$PATH:/usr/local/go/bin' ~/.bashrc || echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc

# ---------------------------------------------------------------------------
# Rust
# ---------------------------------------------------------------------------
echo "==> Installing Rust"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
grep -qxF 'source $HOME/.cargo/env' ~/.bashrc || echo 'source $HOME/.cargo/env' >> ~/.bashrc

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "=================================================================="
echo " Setup complete. Log out and back in (or run 'newgrp docker')"
echo " so your user's docker group membership takes effect."
echo ""
echo " Versions installed:"
docker --version || true
kubectl version --client || true
psql --version || true
mongod --version | head -1 || true
redis-server --version || true
neo4j --version || true
echo "=================================================================="
