# Lab401 — Ubuntu 26.04 Auto Setup

สคริปต์ตั้งค่าและติดตั้งซอฟต์แวร์อัตโนมัติสำหรับ Ubuntu 26.04

---

## 📁 โครงสร้างไฟล์

```
repo/
├── install.sh              ← จุดเริ่มต้น (ดาวน์โหลดและตั้งค่าทุกอย่าง)
├── network.sh              ← ตั้งค่า Static IP ตาม MAC address
├── ubuntu-setup.sh         ← ติดตั้งซอฟต์แวร์ทั้งหมด
├── lab401-network.service  ← systemd service (auto-run network.sh ตอน boot)
└── README.md
```

---

## 🚀 ติดตั้งด้วย One-Liner (ทุกเครื่อง)

```bash
bash <(curl -fsSL https://gitlab.com/YOUR_GROUP/YOUR_REPO/-/raw/main/install.sh)
```

หรือใช้ wget:

```bash
bash <(wget -qO- https://gitlab.com/YOUR_GROUP/YOUR_REPO/-/raw/main/install.sh)
```

> **ต้องรันด้วย sudo:**
> ```bash
> sudo bash <(curl -fsSL https://gitlab.com/YOUR_GROUP/YOUR_REPO/-/raw/main/install.sh)
> ```

---

## ⚙️ install.sh ทำอะไร?

1. ดาวน์โหลด `network.sh` → `/usr/local/bin/lab401-network.sh`
2. ดาวน์โหลด `ubuntu-setup.sh` → `/usr/local/bin/lab401-ubuntu-setup.sh`
3. ติดตั้ง `lab401-network.service` → เปิดใช้งาน auto-run ตอน boot
4. รัน `network.sh` ทันที (ตั้งค่า Static IP)
5. ถามว่าต้องการติดตั้ง software ทั้งหมดด้วยเลยไหม

---

## 🌐 network.sh

ตั้งค่า Static IP โดยอ่าน MAC address เทียบกับตาราง แล้วกำหนด:

| รายการ     | ค่า              |
|-----------|-----------------|
| IP Range  | 172.16.1.101–140 |
| Gateway   | 172.16.1.254     |
| DNS       | 203.158.177.9, 203.158.178.11 |

**รันแมนนวล:**
```bash
sudo lab401-network.sh
```

**ตรวจสอบ log boot:**
```bash
journalctl -u lab401-network.service
```

**หยุด auto-run:**
```bash
sudo systemctl disable lab401-network.service
```

---

## 📦 ubuntu-setup.sh ติดตั้งอะไรบ้าง?

| # | ซอฟต์แวร์ |
|---|-----------|
| 1 | Timeshift |
| 2 | Wireshark |
| 3 | Git |
| 4 | VLC |
| 5 | PuTTY |
| 6 | OpenSSH Server |
| 7 | Visual Studio Code |
| 8 | Google Chrome |
| 9 | Node.js v24 (NVM) |
| 10 | Python 3 + pip + venv |
| 11 | Go |
| 12 | Cisco Packet Tracer* |
| 13 | Custom Fonts* |
| 14 | Keyboard Layout (US+TH) |
| 15 | Docker |
| 16 | Docker Rootless |

> *ต้องวางไฟล์ไว้ก่อน:
> - `~/Downloads/CiscoPacketTracer_900_Ubuntu_64bit.deb`
> - `~/Downloads/Fonts/` (โฟลเดอร์ font)

---

## 🔧 ขั้นตอนอัปโหลดขึ้น GitLab

```bash
git init
git remote add origin https://gitlab.com/YOUR_GROUP/YOUR_REPO.git
git add .
git commit -m "init: Lab401 Ubuntu 26.04 setup scripts"
git push -u origin main
```

จากนั้นแก้ `GITLAB_RAW` ใน `install.sh` ให้ตรงกับ URL repo ของคุณ
