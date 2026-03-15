#!/usr/bin/env bash
# =============================================================================
#  server-setup.sh
#  Ubuntu Server Hardening + k3s Installation
#  Based on: https://github.com/sayjeyhi/shipping-apps-zero-to-hero (steps 01–04)
# =============================================================================
set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }
section() { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════════${RESET}"; \
            echo -e "${BOLD}${CYAN}  $*${RESET}"; \
            echo -e "${BOLD}${CYAN}══════════════════════════════════════════════${RESET}\n"; }

# ── Root check ────────────────────────────────────────────────────────────────
[[ $EUID -ne 0 ]] && error "Please run this script as root or with sudo."

# ── Detect Ubuntu ─────────────────────────────────────────────────────────────
if ! grep -qi ubuntu /etc/os-release 2>/dev/null; then
  warn "This script is designed for Ubuntu. Proceed with caution on other distros."
fi

# =============================================================================
#  STEP 0 – Gather user input
# =============================================================================
section "Step 0 – Configuration"

# ── New sudo user ─────────────────────────────────────────────────────────────
read -rp "$(echo -e "${BOLD}New admin username${RESET} (leave blank to skip user creation): ")" NEW_USER
if [[ -n "$NEW_USER" ]]; then
  read -rsp "$(echo -e "${BOLD}Password for ${NEW_USER}${RESET}: ")" NEW_USER_PASS; echo
  [[ -z "$NEW_USER_PASS" ]] && error "Password cannot be empty."
fi

# ── SSH public key ─────────────────────────────────────────────────────────────
read -rp "$(echo -e "${BOLD}Paste your SSH public key${RESET} (leave blank to skip): ")" SSH_PUB_KEY

# ── SSH port ──────────────────────────────────────────────────────────────────
read -rp "$(echo -e "${BOLD}SSH port${RESET} [default: 2222]: ")" SSH_PORT
SSH_PORT=${SSH_PORT:-2222}
[[ "$SSH_PORT" =~ ^[0-9]+$ && "$SSH_PORT" -ge 1 && "$SSH_PORT" -le 65535 ]] \
  || error "Invalid port: $SSH_PORT"

# ── Firewall: allowed TCP ports ───────────────────────────────────────────────
DEFAULT_EXTRA_PORTS="80,443,6443"
read -rp "$(echo -e "${BOLD}Additional UFW TCP ports to allow${RESET} [default: ${DEFAULT_EXTRA_PORTS}]: ")" EXTRA_PORTS
EXTRA_PORTS=${EXTRA_PORTS:-$DEFAULT_EXTRA_PORTS}

# ── k3s options ───────────────────────────────────────────────────────────────
read -rp "$(echo -e "${BOLD}k3s version${RESET} (e.g. v1.29.3+k3s1 — leave blank for latest): ")" K3S_VERSION
read -rp "$(echo -e "${BOLD}k3s node role${RESET} [server/agent, default: server]: ")" K3S_ROLE
K3S_ROLE=${K3S_ROLE:-server}
[[ "$K3S_ROLE" == "agent" ]] && \
  read -rp "$(echo -e "${BOLD}k3s server URL${RESET} (e.g. https://<server-ip>:6443): ")" K3S_SERVER_URL && \
  read -rsp "$(echo -e "${BOLD}k3s node token${RESET}: ")" K3S_TOKEN && echo

echo
info "Configuration summary:"
echo "  New user      : ${NEW_USER:-<skipped>}"
echo "  SSH port      : $SSH_PORT"
echo "  Extra ports   : $EXTRA_PORTS"
echo "  k3s version   : ${K3S_VERSION:-latest}"
echo "  k3s role      : $K3S_ROLE"
echo
read -rp "$(echo -e "${BOLD}Continue? [y/N]${RESET} ")" CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { info "Aborted."; exit 0; }

# =============================================================================
#  STEP 1 – System update & essential packages
# =============================================================================
section "Step 1 – System Update & Essential Packages"

export DEBIAN_FRONTEND=noninteractive
info "Updating package lists and upgrading installed packages…"
apt-get update -qq
apt-get upgrade -y -qq
apt-get dist-upgrade -y -qq
apt-get autoremove -y -qq

info "Installing essential packages…"
apt-get install -y -qq \
  curl wget git vim nano \
  ufw fail2ban \
  unattended-upgrades apt-listchanges \
  net-tools htop iotop \
  ca-certificates gnupg lsb-release \
  jq

success "System updated and packages installed."

# =============================================================================
#  STEP 2 – Create admin user
# =============================================================================
section "Step 2 – Admin User Setup"

if [[ -n "$NEW_USER" ]]; then
  if id "$NEW_USER" &>/dev/null; then
    warn "User '$NEW_USER' already exists — skipping creation."
  else
    useradd -m -s /bin/bash -G sudo "$NEW_USER"
    echo "$NEW_USER:$NEW_USER_PASS" | chpasswd
    success "User '$NEW_USER' created and added to sudo group."
  fi

  if [[ -n "$SSH_PUB_KEY" ]]; then
    USER_HOME=$(getent passwd "$NEW_USER" | cut -d: -f6)
    mkdir -p "$USER_HOME/.ssh"
    echo "$SSH_PUB_KEY" >> "$USER_HOME/.ssh/authorized_keys"
    chmod 700 "$USER_HOME/.ssh"
    chmod 600 "$USER_HOME/.ssh/authorized_keys"
    chown -R "$NEW_USER:$NEW_USER" "$USER_HOME/.ssh"
    success "SSH public key added for '$NEW_USER'."
  fi
else
  # Still add SSH key for root if no new user was created
  if [[ -n "$SSH_PUB_KEY" ]]; then
    mkdir -p /root/.ssh
    echo "$SSH_PUB_KEY" >> /root/.ssh/authorized_keys
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/authorized_keys
    success "SSH public key added for root."
  fi
  warn "No new user created. Running k3s as root."
fi

# =============================================================================
#  STEP 3 – SSH Hardening
# =============================================================================
section "Step 3 – SSH Hardening"

SSHD_CONFIG="/etc/ssh/sshd_config"
cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
info "Backed up $SSHD_CONFIG"

apply_sshd() {
  local key="$1" val="$2"
  if grep -qE "^#?${key}" "$SSHD_CONFIG"; then
    sed -i -E "s|^#?${key}.*|${key} ${val}|" "$SSHD_CONFIG"
  else
    echo "${key} ${val}" >> "$SSHD_CONFIG"
  fi
}

apply_sshd Port                   "$SSH_PORT"
apply_sshd Protocol                2
apply_sshd PermitRootLogin         "no"
apply_sshd PasswordAuthentication  "no"
apply_sshd PubkeyAuthentication    "yes"
apply_sshd AuthorizedKeysFile      ".ssh/authorized_keys"
apply_sshd PermitEmptyPasswords    "no"
apply_sshd X11Forwarding           "no"
apply_sshd MaxAuthTries            3
apply_sshd LoginGraceTime          30
apply_sshd ClientAliveInterval     300
apply_sshd ClientAliveCountMax     2
apply_sshd UseDNS                  "no"
apply_sshd AllowAgentForwarding    "no"
apply_sshd AllowTcpForwarding      "no"
apply_sshd PermitUserEnvironment   "no"

# If a new user was created, restrict SSH to that user only
if [[ -n "$NEW_USER" ]]; then
  apply_sshd AllowUsers "$NEW_USER"
fi

# Remove weak host key algorithms
sed -i '/^HostKey.*ecdsa/d' "$SSHD_CONFIG" 2>/dev/null || true
sed -i '/^HostKey.*dsa/d'   "$SSHD_CONFIG" 2>/dev/null || true

# Prefer strong ciphers / MACs / KexAlgorithms
{
  echo ""
  echo "# Hardened cipher/MAC/KexAlgorithm settings"
  echo "KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group14-sha256,diffie-hellman-group16-sha512"
  echo "Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com"
  echo "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com"
} >> "$SSHD_CONFIG"

sshd -t && systemctl restart ssh
success "SSH hardened (port $SSH_PORT, key-only auth, root login disabled)."

# =============================================================================
#  STEP 4 – Firewall (UFW)
# =============================================================================
section "Step 4 – Firewall (UFW)"

ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow "$SSH_PORT/tcp" comment "SSH"

# k3s required ports
ufw allow 6443/tcp  comment "k3s API server"
ufw allow 10250/tcp comment "k3s kubelet"
ufw allow 8472/udp  comment "k3s flannel VXLAN"
ufw allow 51820/udp comment "k3s WireGuard IPv4"
ufw allow 51821/udp comment "k3s WireGuard IPv6"

# User-specified extra ports
IFS=',' read -ra EXTRA <<< "$EXTRA_PORTS"
for p in "${EXTRA[@]}"; do
  p=$(echo "$p" | tr -d ' ')
  ufw allow "$p/tcp" comment "user-specified"
  info "  UFW: allowed $p/tcp"
done

ufw --force enable
success "UFW enabled."
ufw status verbose

# =============================================================================
#  STEP 5 – Fail2Ban
# =============================================================================
section "Step 5 – Fail2Ban"

cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
backend  = systemd

[sshd]
enabled  = true
port     = $SSH_PORT
logpath  = /var/log/auth.log
maxretry = 3
bantime  = 24h
EOF

systemctl enable fail2ban --quiet
systemctl restart fail2ban
success "Fail2Ban configured (SSH jail on port $SSH_PORT)."

# =============================================================================
#  STEP 6 – Automatic Security Updates
# =============================================================================
section "Step 6 – Unattended Security Updates"

cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

cat > /etc/apt/apt.conf.d/50unattended-upgrades <<EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
EOF

systemctl enable unattended-upgrades --quiet
systemctl restart unattended-upgrades
success "Automatic security updates enabled."

# =============================================================================
#  STEP 7 – Kernel / sysctl hardening
# =============================================================================
section "Step 7 – Kernel Hardening (sysctl)"

cat > /etc/sysctl.d/99-hardening.conf <<EOF
# IP spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Block SYN attacks
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# Log suspicious packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Disable IPv6 if not needed (comment out if you use IPv6)
# net.ipv6.conf.all.disable_ipv6 = 1

# Required for k3s / Kubernetes networking
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system -q
success "Kernel parameters applied."

# =============================================================================
#  STEP 8 – Install k3s
# =============================================================================
section "Step 8 – Install k3s"

# Load br_netfilter module (required for k3s)
modprobe br_netfilter 2>/dev/null || true
echo "br_netfilter" >> /etc/modules-load.d/k3s.conf

if [[ "$K3S_ROLE" == "server" ]]; then
  info "Installing k3s as SERVER node…"
  if [[ -n "$K3S_VERSION" ]]; then
    INSTALL_K3S_VERSION="$K3S_VERSION" \
      curl -sfL https://get.k3s.io | sh -s - server \
        --write-kubeconfig-mode 644
  else
    curl -sfL https://get.k3s.io | sh -s - server \
      --write-kubeconfig-mode 644
  fi

  # Wait for k3s to become ready
  info "Waiting for k3s to start…"
  for i in {1..30}; do
    if systemctl is-active --quiet k3s; then break; fi
    sleep 2
  done

  systemctl is-active --quiet k3s \
    || error "k3s failed to start. Check: journalctl -xeu k3s"

  success "k3s server installed and running."

  # Show node token for future agent additions
  echo
  info "Node token (save this for adding agent nodes):"
  cat /var/lib/rancher/k3s/server/node-token
  echo
  info "kubeconfig is at: /etc/rancher/k3s/k3s.yaml"
  echo
  info "Verify cluster with:  kubectl get nodes"

else
  # Agent node
  [[ -z "${K3S_SERVER_URL:-}" ]] && error "K3S_SERVER_URL is required for agent nodes."
  [[ -z "${K3S_TOKEN:-}"      ]] && error "K3S_TOKEN is required for agent nodes."

  info "Installing k3s as AGENT node → $K3S_SERVER_URL…"
  if [[ -n "$K3S_VERSION" ]]; then
    INSTALL_K3S_VERSION="$K3S_VERSION" K3S_URL="$K3S_SERVER_URL" K3S_TOKEN="$K3S_TOKEN" \
      curl -sfL https://get.k3s.io | sh -
  else
    K3S_URL="$K3S_SERVER_URL" K3S_TOKEN="$K3S_TOKEN" \
      curl -sfL https://get.k3s.io | sh -
  fi

  systemctl is-active --quiet k3s-agent \
    || error "k3s-agent failed to start. Check: journalctl -xeu k3s-agent"

  success "k3s agent installed and running."
fi

# ── kubectl convenience for new user ─────────────────────────────────────────
if [[ -n "$NEW_USER" ]]; then
  USER_HOME=$(getent passwd "$NEW_USER" | cut -d: -f6)
  mkdir -p "$USER_HOME/.kube"
  if [[ -f /etc/rancher/k3s/k3s.yaml ]]; then
    cp /etc/rancher/k3s/k3s.yaml "$USER_HOME/.kube/config"
    chown "$NEW_USER:$NEW_USER" "$USER_HOME/.kube/config"
    chmod 600 "$USER_HOME/.kube/config"
    success "kubeconfig copied to $USER_HOME/.kube/config"
  fi
fi

# =============================================================================
#  DONE
# =============================================================================
section "All Done!"

echo -e "${GREEN}${BOLD}"
echo "  ✔  System updated & packages installed"
echo "  ✔  Admin user configured"
echo "  ✔  SSH hardened (port: $SSH_PORT, key-only auth)"
echo "  ✔  UFW firewall enabled"
echo "  ✔  Fail2Ban configured"
echo "  ✔  Automatic security updates enabled"
echo "  ✔  Kernel hardening applied"
echo "  ✔  k3s installed (role: $K3S_ROLE)"
echo -e "${RESET}"

warn "⚠  IMPORTANT: Your SSH port is now ${BOLD}$SSH_PORT${RESET}${YELLOW}."
warn "   Open a NEW terminal and verify you can log in BEFORE closing this session!"
if [[ -n "$NEW_USER" ]]; then
  warn "   Login: ssh -p $SSH_PORT $NEW_USER@<server-ip>"
fi
echo
