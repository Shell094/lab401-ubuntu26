#!/bin/bash
# ============================================================
#  Lab401 — Master Installer
#  ดาวน์โหลดและติดตั้งสคริปต์ทั้งหมดจาก GitHub
#  Ubuntu 26.04
#
#  วิธีใช้งาน (one-liner):
#    bash <(curl -fsSL https://gitlab.com/<group>/<repo>/-/raw/main/install.sh)
#  หรือ
#    bash <(wget -qO- https://gitlab.com/<group>/<repo>/-/raw/main/install.sh)
# ============================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[✔]${NC} $*"; }
info() { echo -e "${CYAN}[→]${NC}  $*"; }
warn() { echo -e "${YELLOW}[!]${NC}  $*"; }
die()  { echo -e "${RED}[✘]${NC}  $*"; exit 1; }

[[ $EUID -eq 0 ]] || die "กรุณารันด้วย sudo"

# ============================================================
# ★ แก้ URL ตรงนี้ให้ตรงกับ GitHub repo
# ============================================================
GITHUB_RAW="https://raw.githubusercontent.com/Shell094/lab401-ubuntu26/main"
# ============================================================

INSTALL_DIR="/usr/local/bin"
SERVICE_DIR="/etc/systemd/system"

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════╗"
echo "║   Lab401 — Master Installer                  ║"
echo "║   Ubuntu 26.04                               ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# ── ตรวจสอบ dependencies ──────────────────────────────────
for cmd in curl systemctl nmcli; do
  command -v "$cmd" &>/dev/null || die "ไม่พบ $cmd กรุณาติดตั้งก่อน"
done

# ── ดาวน์โหลด network.sh ──────────────────────────────────
info "ดาวน์โหลด network.sh จาก GitHub..."
curl -fsSL "${GITHUB_RAW}/network.sh" -o "${INSTALL_DIR}/lab401-network.sh"
chmod +x "${INSTALL_DIR}/lab401-network.sh"
ok "บันทึกที่ ${INSTALL_DIR}/lab401-network.sh"

# ── ดาวน์โหลด ubuntu-setup.sh ────────────────────────────
info "ดาวน์โหลด ubuntu-setup.sh จาก GitHub..."
curl -fsSL "${GITHUB_RAW}/ubuntu-setup.sh" -o "${INSTALL_DIR}/lab401-ubuntu-setup.sh"
chmod +x "${INSTALL_DIR}/lab401-ubuntu-setup.sh"
ok "บันทึกที่ ${INSTALL_DIR}/lab401-ubuntu-setup.sh"

# ── ติดตั้ง systemd service (auto-run network.sh ตอน boot) ──
info "ติดตั้ง systemd service..."
curl -fsSL "${GITHUB_RAW}/lab401-network.service" -o "${SERVICE_DIR}/lab401-network.service"

systemctl daemon-reload
systemctl enable lab401-network.service
ok "เปิดใช้งาน lab401-network.service แล้ว (จะรันทุกครั้งที่ boot)"

# ── รัน network.sh ทันที ──────────────────────────────────
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
info "รัน network.sh เพื่อตั้งค่า Static IP ทันที..."
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
bash "${INSTALL_DIR}/lab401-network.sh"

# ── ถาม setup software ──────────────────────────────────
echo ""
read -rp "ต้องการติดตั้ง software ทั้งหมด (ubuntu-setup.sh) ด้วยเลยไหม? (y/N): " do_setup
if [[ "${do_setup,,}" == "y" ]]; then
  info "รัน ubuntu-setup.sh..."
  bash "${INSTALL_DIR}/lab401-ubuntu-setup.sh"
else
  warn "ข้ามการติดตั้ง software"
  echo "  รันได้ในภายหลังด้วย: sudo lab401-ubuntu-setup.sh"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅  ติดตั้งเสร็จสมบูรณ์!                   ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  network.sh  จะรันอัตโนมัติทุกครั้งที่ boot  ║${NC}"
echo -e "${GREEN}║                                              ║${NC}"
echo -e "${GREEN}║  คำสั่งที่ใช้ได้:                            ║${NC}"
echo -e "${GREEN}║  sudo lab401-network.sh    (ตั้ง IP)         ║${NC}"
echo -e "${GREEN}║  sudo lab401-ubuntu-setup.sh (ติดตั้งทุกอย่าง)║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
warn "แนะนำให้ reboot: sudo reboot"
