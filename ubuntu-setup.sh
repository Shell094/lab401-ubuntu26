#!/bin/bash
# ============================================================
#  Ubuntu 26.04 — Auto Setup Script
#  สคริปต์ติดตั้งซอฟต์แวร์อัตโนมัติ
# ============================================================

set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
log()    { echo -e "${GREEN}[✔] $1${NC}"; }
warn()   { echo -e "${YELLOW}[!] $1${NC}"; }
header() { echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n${CYAN}  $1${NC}\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }

[ "$EUID" -ne 0 ] && { echo -e "${RED}[✘] กรุณารันด้วย sudo${NC}"; exit 1; }

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")

header "อัปเดตระบบ"
apt update && apt upgrade -y && log "อัปเดตเสร็จสิ้น"

header "1. Timeshift"
apt install -y timeshift && log "Timeshift OK"

header "2. Wireshark"
apt install -y "libre2-11:amd64=20250805-1build3" 2>/dev/null || warn "libre2-11 ไม่พบ — ข้ามไป"
DEBIAN_FRONTEND=noninteractive apt install -y wireshark && log "Wireshark OK"

header "3. Git"
apt install -y git && log "Git OK"

header "4. VLC"
apt install -y vlc && log "VLC OK"

header "5. PuTTY"
apt install -y putty && log "PuTTY OK"

header "6. OpenSSH Server"
apt install -y "openssh-client=1:10.2p1-2ubuntu3.2" 2>/dev/null || apt install -y openssh-client
apt install -y openssh-server
systemctl start ssh.service && systemctl enable ssh.service
log "OpenSSH Server OK"

header "7. Visual Studio Code"
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/ms.gpg
install -D -o root -g root -m 644 /tmp/ms.gpg /etc/apt/keyrings/microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
  | tee /etc/apt/sources.list.d/vscode.list > /dev/null
apt update && apt install -y code && log "VS Code OK"

header "8. Google Chrome"
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | tee /etc/apt/trusted.gpg.d/google.asc > /dev/null
echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/google.asc] https://dl.google.com/linux/chrome/deb/ stable main" \
  | tee /etc/apt/sources.list.d/google-chrome.list
apt update && apt install -y google-chrome-stable && log "Google Chrome OK"

header "9. Node.js (NVM v24)"
sudo -u "$REAL_USER" bash -c '
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm install 24 && nvm use default 24
  echo "Node: $(node -v) | npm: $(npm -v)"
'
grep -q 'NVM_DIR' /etc/skel/.bashrc 2>/dev/null || cat >> /etc/skel/.bashrc << 'NEOF'

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
NEOF
log "Node.js OK"

header "10. Python 3"
apt install -y python3 python3-pip python3-venv && log "Python OK"

header "11. Go"
apt install -y golang && log "Go OK"

header "12. Cisco Packet Tracer"
PT_DEB="$REAL_HOME/Downloads/CiscoPacketTracer_900_Ubuntu_64bit.deb"
if [ -f "$PT_DEB" ]; then
  dpkg -i "$PT_DEB" || true
  apt --fix-broken install -y
  apt install -y libfuse2 libpcre2-dev
  log "Cisco Packet Tracer OK"
else
  warn "ไม่พบ $PT_DEB — ข้ามไป (ดาวน์โหลดจาก netacad.com)"
fi

header "13. Fonts"
mkdir -p /usr/local/share/fonts/custom
FONTS_DIR="$REAL_HOME/Downloads/Fonts"
if [ -d "$FONTS_DIR" ]; then
  cp "$FONTS_DIR"/* /usr/local/share/fonts/custom/ && fc-cache -f -v && log "Fonts OK"
else
  warn "ไม่พบ $FONTS_DIR — ข้ามไป"
fi

header "14. Keyboard Layout (US+TH)"
cat > /etc/default/keyboard << 'KEOF'
XKBMODEL="pc105"
XKBLAYOUT="us,th"
XKBVARIANT=","
XKBOPTIONS="grp:alt_shift_toggle,terminate:ctrl_alt_bksp,grp_led:scroll"
BACKSPACE="guess"
KEOF
dpkg-reconfigure -f noninteractive keyboard-configuration && log "Keyboard OK (Alt+Shift สลับภาษา)"

header "15. Docker"
apt install -y curl apt-transport-https ca-certificates software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update && apt install -y docker-ce docker-ce-cli containerd.io
systemctl enable docker && systemctl start docker
usermod -aG docker "$REAL_USER"
log "Docker $(docker --version) OK"

header "16. Docker Rootless"
apt install -y uidmap dbus-user-session sssd

tee /usr/local/bin/setup-docker-rootless.sh << 'EOF'
#!/bin/bash
grep -q "^$PAM_USER:" /etc/subuid || echo "$PAM_USER:100000:65536" >> /etc/subuid
grep -q "^$PAM_USER:" /etc/subgid || echo "$PAM_USER:100000:65536" >> /etc/subgid
loginctl enable-linger "$PAM_USER"
EOF
chmod +x /usr/local/bin/setup-docker-rootless.sh
grep -q 'setup-docker-rootless' /etc/pam.d/common-session || \
  echo "session optional pam_exec.so /usr/local/bin/setup-docker-rootless.sh" >> /etc/pam.d/common-session

tee /etc/profile.d/docker-rootless.sh << 'EOF'
export PATH=$HOME/bin:$PATH
export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock
[ ! -f "$HOME/.config/systemd/user/docker.service" ] && \
  dockerd-rootless-setuptool.sh install --force 2>/dev/null
EOF
chmod +x /etc/profile.d/docker-rootless.sh

tee /usr/local/bin/add-to-docker.sh << 'EOF'
#!/bin/bash
usermod -aG docker "$PAM_USER" 2>/dev/null
EOF
chmod +x /usr/local/bin/add-to-docker.sh
grep -q 'add-to-docker' /etc/pam.d/common-session || \
  echo "session optional pam_exec.so /usr/local/bin/add-to-docker.sh" >> /etc/pam.d/common-session

grep -q 'docker rootless' /etc/skel/.bashrc 2>/dev/null || cat >> /etc/skel/.bashrc << 'DEOF'

# Docker Rootless
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export PATH=/usr/bin:$PATH
export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock
DEOF
log "Docker Rootless OK"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅  การติดตั้งทั้งหมดเสร็จสิ้น!            ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  กรุณา reboot เพื่อให้ทุกการตั้งค่ามีผล      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
