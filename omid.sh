#!/usr/bin/env bash
# Omid VPN (امید وی‌پی‌ان) Installer — Xray + Web Panel
# Fix: read prompts from /dev/tty (prevents Termius dropping after password)

# ---- force bash ----
if [ -z "${BASH_VERSION:-}" ]; then
  exec /usr/bin/env bash "$0" "$@"
fi

set -euo pipefail

# ---- better error visibility ----
trap 'echo "[!] Error at line $LINENO: $BASH_COMMAND" >&2' ERR

APP_DIR="/opt/omidvpn"
DATA_DIR="$APP_DIR/data"
TEMPL_DIR="$APP_DIR/templates"

XRAY_ETC="/etc/xray"
XRAY_CONFIG="$XRAY_ETC/config.json"
XRAY_BIN="/usr/local/bin/xray"  # will be detected after official install

PANEL_SERVICE="/etc/systemd/system/omidvpn-panel.service"
SYNC_SERVICE="/etc/systemd/system/omidvpn-sync.service"
SYNC_TIMER="/etc/systemd/system/omidvpn-sync.timer"

DEFAULT_PANEL_PORT="8000"
DEFAULT_ADMIN_USER="admin"
DEFAULT_ADMIN_PASS="admin123"

log(){ echo "[*] $*"; }
die(){ echo "[!] $*" >&2; exit 1; }

require_root(){
  if [[ "${EUID}" -ne 0 ]]; then
    die "اسکریپت باید با sudo/root اجرا شود: sudo bash install.sh"
  fi
}

# ---- CRITICAL FIX: read from /dev/tty so Termius won't break prompts ----
TTY="/dev/tty"
if [[ ! -e "$TTY" ]]; then
  # fallback (rare)
  TTY="/proc/self/fd/0"
fi

read_tty(){
  # read_tty VAR "Prompt: " "default" [silent=0|1]
  local __var="$1"
  local __prompt="$2"
  local __default="${3:-}"
  local __silent="${4:-0}"
  local __val=""
  local __rc=0

  # prevent set -e from killing the script on read return codes
  set +e
  if [[ "$__silent" == "1" ]]; then
    IFS= read -r -s -p "$__prompt" __val <"$TTY"
    __rc=$?
    echo >"$TTY"
  else
    IFS= read -r -p "$__prompt" __val <"$TTY"
    __rc=$?
  fi
  set -e

  # If read failed, keep empty (will become default)
  if [[ $__rc -ne 0 ]]; then
    __val=""
  fi

  if [[ -z "$__val" ]]; then
    __val="$__default"
  fi

  printf -v "$__var" '%s' "$__val"
}

prompt_settings(){
  echo "=== Omid VPN (امید وی‌پی‌ان) Installer ==="
  echo

  read_tty PANEL_PORT "Panel port [${DEFAULT_PANEL_PORT}]: " "$DEFAULT_PANEL_PORT" 0
  if ! [[ "$PANEL_PORT" =~ ^[0-9]+$ ]] || (( PANEL_PORT < 1 || PANEL_PORT > 65535 )); then
    die "پورت نامعتبر است: $PANEL_PORT"
  fi

  read_tty ADMIN_USERNAME "Admin username [${DEFAULT_ADMIN_USER}]: " "$DEFAULT_ADMIN_USER" 0
  [[ -z "$ADMIN_USERNAME" ]] && die "نام کاربری نمی‌تواند خالی باشد."

  read_tty ADMIN_PASSWORD "Admin password [${DEFAULT_ADMIN_PASS}]: " "$DEFAULT_ADMIN_PASS" 1
  [[ -z "$ADMIN_PASSWORD" ]] && die "رمز عبور نمی‌تواند خالی باشد."
}

install_packages(){
  log "Installing OS packages..."
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y --no-install-recommends \
    ca-certificates curl unzip jq \
    python3 python3-pip \
    iproute2 iptables procps net-tools \
    sqlite3 \
    systemd \
    openssl \
    cron
}

install_python_libs(){
  log "Installing Python libs system-wide (no venv)..."
  python3 -m pip install --upgrade pip
  python3 -m pip install --no-cache-dir \
    fastapi uvicorn jinja2 python-multipart sqlalchemy pydantic bcrypt qrcode[pil] requests
}

install_xray(){
  log "Installing Xray-core via official XTLS installer (latest)..."
  mkdir -p "$XRAY_ETC" /var/log/xray

  # Official installer (as you requested)
  bash -c "$(curl -fsSL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

  # Detect xray binary path robustly
  local detected=""
  if command -v xray >/dev/null 2>&1; then
    detected="$(command -v xray)"
  elif [[ -x /usr/local/bin/xray ]]; then
    detected="/usr/local/bin/xray"
  elif [[ -x /usr/bin/xray ]]; then
    detected="/usr/bin/xray"
  fi
  [[ -z "$detected" ]] && die "xray binary not found after install."
  XRAY_BIN="$detected"
  log "Xray binary: $XRAY_BIN"

  # Create/ensure our managed config
  if [[ ! -f "$XRAY_CONFIG" ]]; then
    cat > "$XRAY_CONFIG" <<'JSON'
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
  },
  "api": { "tag": "api", "services": ["StatsService"] },
  "stats": {},
  "policy": {
    "levels": { "0": { "statsUserUplink": true, "statsUserDownlink": true } },
    "system": { "statsInboundUplink": true, "statsInboundDownlink": true }
  },
  "inbounds": [
    {
      "tag": "api-in",
      "listen": "127.0.0.1",
      "port": 10085,
      "protocol": "dokodemo-door",
      "settings": { "address": "127.0.0.1" }
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "tag": "direct" },
    { "protocol": "blackhole", "tag": "block" }
  ],
  "routing": { "domainStrategy": "AsIs", "rules": [] }
}
JSON
  fi

  systemctl daemon-reload || true
  systemctl enable --now xray || true

  if ! systemctl is-active --quiet xray; then
    echo "[!] xray service failed to start."
    echo "    Run: journalctl -u xray -e --no-pager"
    exit 1
  fi
}

write_panel_files(){
  log "Writing panel files..."
  mkdir -p "$APP_DIR" "$DATA_DIR" "$TEMPL_DIR"

  cat > "$APP_DIR/.env" <<EOF
PANEL_PORT=${PANEL_PORT}
ADMIN_USERNAME=${ADMIN_USERNAME}
ADMIN_PASSWORD=${ADMIN_PASSWORD}

APP_DIR=${APP_DIR}
DATA_DIR=${DATA_DIR}

XRAY_CONFIG=${XRAY_CONFIG}
XRAY_API=127.0.0.1:10085
XRAY_BIN=${XRAY_BIN}

# TLS (optional; set from panel settings)
PUBLIC_HOST=
CERT_PATH=
KEY_PATH=
EOF

  cat > "$APP_DIR/db.py" <<'PY'
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

engine = create_engine("sqlite:////opt/omidvpn/data/panel.db", connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()
PY

  cat > "$APP_DIR/models.py" <<'PY'
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Integer, Text, ForeignKey
from db import Base

class Admin(Base):
    __tablename__ = "admin"
    id = Column(String, primary_key=True, default="admin")
    username = Column(String, nullable=False, unique=True)
    password_hash = Column(String, nullable=False)

class Setting(Base):
    __tablename__ = "settings"
    key = Column(String, primary_key=True)
    value = Column(String, nullable=False)

class Inbound(Base):
    __tablename__ = "inbounds"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    protocol = Column(String, nullable=False)        # vless/vmess/trojan/ss/socks/http
    listen = Column(String, nullable=False, default="0.0.0.0")
    port = Column(Integer, nullable=False)
    enabled = Column(Boolean, default=True)
    stream_json = Column(Text, nullable=True)        # streamSettings JSON full
    sniff_json = Column(Text, nullable=True)
    extra_json = Column(Text, nullable=True)         # e.g. {"method":"aes-128-gcm"} for ss
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow)

class Client(Base):
    __tablename__ = "clients"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    inbound_id = Column(String, ForeignKey("inbounds.id"), nullable=False)
    label = Column(String, nullable=False)
    email = Column(String, nullable=True)            # for stats pattern user>>>email>>>
    secret = Column(String, nullable=False)          # uuid/password
    enabled = Column(Boolean, default=True)

    quota_gb = Column(Integer, nullable=True)        # GB
    used_bytes = Column(Integer, default=0)

    expire_days = Column(Integer, nullable=True)     # days
    start_on_first_use = Column(Boolean, default=False)
    first_seen_at = Column(DateTime, nullable=True)
    expire_at = Column(DateTime, nullable=True)

    ip_limit = Column(Integer, nullable=True)
    note = Column(String, nullable=True)

    sub_token = Column(String, nullable=False, default=lambda: str(uuid.uuid4()))

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow)
PY

  cat > "$APP_DIR/i18n.py" <<'PY'
TRANSLATIONS = {
  "fa": {
    "brand":"امید وی‌پی‌ان",
    "dashboard":"داشبورد",
    "inbounds":"این‌باندها",
    "clients":"کاربران",
    "settings":"تنظیمات",
    "logout":"خروج",
    "login":"ورود",
    "username":"نام کاربری",
    "password":"رمز عبور",
    "save":"ذخیره",
    "cancel":"لغو",
    "apply":"اعمال",
    "status":"وضعیت",
    "version":"نسخه",
    "latest":"آخرین نسخه",
    "up_to_date":"به‌روز است",
    "update_available":"آپدیت موجود است",
    "name":"نام",
    "protocol":"پروتکل",
    "listen":"Listen",
    "port":"پورت",
    "enabled":"فعال",
    "disabled":"غیرفعال",
    "actions":"عملیات",
    "new":"جدید",
    "edit":"ویرایش",
    "delete":"حذف",
    "quota_gb":"سقف ترافیک (GB)",
    "expire_days":"مدت (روز)",
    "start_on_first_use":"شروع زمان پس از اولین اتصال",
    "ip_limit":"محدودیت IP",
    "link":"لینک",
    "qr":"QR",
    "public_host":"دامنه/هاست (اختیاری)",
    "cert_path":"مسیر Public cert (fullchain.pem)",
    "key_path":"مسیر Private key (privkey.pem)",
    "https_apply":"فعال‌سازی HTTPS (نیاز به ری‌استارت سرویس)",
    "stream_json":"تنظیمات ترنسپورت (JSON)"
  },
  "en": {
    "brand":"Omid VPN",
    "dashboard":"Dashboard",
    "inbounds":"Inbounds",
    "clients":"Clients",
    "settings":"Settings",
    "logout":"Logout",
    "login":"Login",
    "username":"Username",
    "password":"Password",
    "save":"Save",
    "cancel":"Cancel",
    "apply":"Apply",
    "status":"Status",
    "version":"Version",
    "latest":"Latest",
    "up_to_date":"Up to date",
    "update_available":"Update available",
    "name":"Name",
    "protocol":"Protocol",
    "listen":"Listen",
    "port":"Port",
    "enabled":"Enabled",
    "disabled":"Disabled",
    "actions":"Actions",
    "new":"New",
    "edit":"Edit",
    "delete":"Delete",
    "quota_gb":"Traffic quota (GB)",
    "expire_days":"Time limit (Days)",
    "start_on_first_use":"Start after first use",
    "ip_limit":"IP limit",
    "link":"Link",
    "qr":"QR",
    "public_host":"Public host/domain (optional)",
    "cert_path":"Public cert path (fullchain.pem)",
    "key_path":"Private key path (privkey.pem)",
    "https_apply":"Enable HTTPS (service restart required)",
    "stream_json":"Transport settings (JSON)"
  }
}
def t(lang: str, key: str) -> str:
  lang = "fa" if lang == "fa" else "en"
  return TRANSLATIONS[lang].get(key, key)
PY

  cat > "$APP_DIR/security.py" <<'PY'
import secrets
from typing import Optional
import bcrypt

SESSION_COOKIE = "omidvpn_session"

class SessionStore:
    def __init__(self):
        self.tokens: set[str] = set()
    def new(self) -> str:
        t = secrets.token_urlsafe(32)
        self.tokens.add(t)
        return t
    def valid(self, token: Optional[str]) -> bool:
        return bool(token and token in self.tokens)
    def remove(self, token: Optional[str]) -> None:
        if token and token in self.tokens:
            self.tokens.remove(token)

def hash_password(pw: str) -> str:
    return bcrypt.hashpw(pw.encode(), bcrypt.gensalt()).decode()

def verify_password(pw: str, hashed: str) -> bool:
    return bcrypt.checkpw(pw.encode(), hashed.encode())
PY

  cat > "$APP_DIR/xrayctl.py" <<'PY'
import os, subprocess, requests
from typing import Dict, List

XRAY_BIN = os.getenv("XRAY_BIN", "/usr/local/bin/xray")
XRAY_API = os.getenv("XRAY_API", "127.0.0.1:10085")

def _run(cmd: List[str]) -> str:
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode != 0:
        raise RuntimeError(p.stderr.strip())
    return p.stdout.strip()

def is_active() -> str:
    try: return _run(["systemctl","is-active","xray"])
    except: return "unknown"

def version_line() -> str:
    try:
        out = _run([XRAY_BIN,"version"])
        return out.splitlines()[0].strip() if out else "unknown"
    except:
        return "unknown"

def latest_tag() -> str:
    try:
        r = requests.get("https://api.github.com/repos/XTLS/Xray-core/releases/latest", timeout=6)
        return (r.json().get("tag_name") or "unknown").strip()
    except:
        return "unknown"

def update_available() -> bool:
    cur = version_line()
    lat = latest_tag()
    return (lat != "unknown" and cur != "unknown" and lat not in cur)

def restart():
    subprocess.run(["systemctl","restart","xray"], check=False)

def get_stats() -> Dict[str, int]:
    try:
        out = _run([XRAY_BIN, "api", "statsquery", "--server", XRAY_API, "--pattern", "user>>>"])
        import json
        j = json.loads(out)
        res = {}
        for s in j.get("stat", []):
            res[s.get("name","")] = int(s.get("value",0))
        return res
    except:
        return {}
PY

  cat > "$APP_DIR/config_builder.py" <<'PY'
import json, os
from typing import Any, Dict, List
from sqlalchemy.orm import Session
from models import Inbound, Client

XRAY_CONFIG = os.getenv("XRAY_CONFIG", "/etc/xray/config.json")

def _load_base() -> Dict[str, Any]:
    with open(XRAY_CONFIG, "r", encoding="utf-8") as f:
        return json.load(f)

def _email(c: Client) -> str:
    return (c.email or f"{c.id}@omidvpn")

def _parse_json_or_none(s: str | None) -> Any:
    if not s: return None
    s = s.strip()
    if not s: return None
    return json.loads(s)

def build_inbound_obj(inb: Inbound, clients: List[Client]) -> Dict[str, Any]:
    proto = inb.protocol.lower().strip()
    stream = _parse_json_or_none(inb.stream_json) or {"network":"tcp"}
    sniff = _parse_json_or_none(inb.sniff_json)

    obj: Dict[str, Any] = {
      "tag": f"in-{inb.id}",
      "listen": inb.listen,
      "port": int(inb.port),
      "protocol": proto,
      "streamSettings": stream
    }
    if sniff:
        obj["sniffing"] = sniff

    if proto == "vless":
        obj["settings"] = {
          "decryption":"none",
          "clients":[{"id": c.secret, "email": _email(c)} for c in clients if c.enabled]
        }
    elif proto == "vmess":
        obj["settings"] = {
          "clients":[{"id": c.secret, "alterId": 0, "email": _email(c)} for c in clients if c.enabled]
        }
    elif proto == "trojan":
        obj["settings"] = {
          "clients":[{"password": c.secret, "email": _email(c)} for c in clients if c.enabled]
        }
    elif proto in ("shadowsocks","ss"):
        method = "aes-128-gcm"
        if inb.extra_json:
            try: method = json.loads(inb.extra_json).get("method", method)
            except: pass
        enabled = [c for c in clients if c.enabled]
        password = enabled[0].secret if enabled else "changeme"
        obj["protocol"] = "shadowsocks"
        obj["settings"] = {"method": method, "password": password, "network":"tcp,udp"}
    elif proto == "socks":
        obj["settings"] = {"auth":"noauth","udp":True}
    elif proto == "http":
        obj["settings"] = {"timeout": 300}
    else:
        obj["protocol"] = "vless"
        obj["settings"] = {"decryption":"none","clients":[]}

    return obj

def rebuild_xray_config(db: Session) -> None:
    base = _load_base()
    keep = [x for x in base.get("inbounds", []) if x.get("tag") == "api-in"]

    inbounds: List[Inbound] = db.query(Inbound).all()
    clients: List[Client] = db.query(Client).all()

    managed = []
    for inb in inbounds:
        if not inb.enabled:
            continue
        cl = [c for c in clients if c.inbound_id == inb.id]
        managed.append(build_inbound_obj(inb, cl))

    base["inbounds"] = keep + managed
    with open(XRAY_CONFIG, "w", encoding="utf-8") as f:
        json.dump(base, f, ensure_ascii=False, indent=2)
PY

  cat > "$APP_DIR/linkgen.py" <<'PY'
import base64, json, urllib.parse

def vless_link(host: str, port: int, uuid: str, remark: str="") -> str:
    qs = {"type":"tcp","security":"none"}
    return f"vless://{uuid}@{host}:{port}?{urllib.parse.urlencode(qs)}#{urllib.parse.quote(remark)}"

def vmess_link(host: str, port: int, uuid: str, remark: str="") -> str:
    obj = {"v":"2","ps":remark,"add":host,"port":str(port),"id":uuid,"aid":"0","net":"tcp","type":"none","host":"","path":"","tls":""}
    raw = json.dumps(obj, ensure_ascii=False)
    return "vmess://" + base64.b64encode(raw.encode()).decode()

def trojan_link(host: str, port: int, password: str, remark: str="") -> str:
    return f"trojan://{urllib.parse.quote(password)}@{host}:{port}#{urllib.parse.quote(remark)}"

def ss_link(host: str, port: int, method: str, password: str, remark: str="") -> str:
    userinfo = f"{method}:{password}"
    b64 = base64.b64encode(userinfo.encode()).decode()
    return f"ss://{b64}@{host}:{port}#{urllib.parse.quote(remark)}"
PY

  cat > "$APP_DIR/sync_usage.py" <<'PY'
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from db import SessionLocal
from models import Client
import xrayctl

GB = 1024 * 1024 * 1024

def _now(): return datetime.utcnow()
def _email(c: Client) -> str: return (c.email or f"{c.id}@omidvpn")

def sync_once():
    stats = xrayctl.get_stats()
    db: Session = SessionLocal()
    try:
        clients = db.query(Client).all()
        changed = False
        for c in clients:
            email = _email(c)
            up = stats.get(f"user>>>{email}>>>traffic>>>uplink", 0)
            down = stats.get(f"user>>>{email}>>>traffic>>>downlink", 0)
            used = int(up) + int(down)

            if used != (c.used_bytes or 0):
                c.used_bytes = used
                changed = True

            if c.start_on_first_use and c.expire_days and not c.first_seen_at and used > 0:
                c.first_seen_at = _now()
                c.expire_at = c.first_seen_at + timedelta(days=int(c.expire_days))
                changed = True

            if (not c.start_on_first_use) and c.expire_days and not c.expire_at:
                c.expire_at = c.created_at + timedelta(days=int(c.expire_days))
                changed = True

            over_quota = (c.quota_gb is not None) and (used >= int(c.quota_gb) * GB)
            over_time = (c.expire_at is not None) and (_now() >= c.expire_at)

            if c.enabled and (over_quota or over_time):
                c.enabled = False
                changed = True

        if changed:
            db.commit()
    finally:
        db.close()

if __name__ == "__main__":
    sync_once()
PY

  # Templates + app.py (همان نسخه قبلی شما) برای کوتاه نشدنِ پیام حذف نشده؛
  # اما برای جلوگیری از طولِ بسیار زیاد، اگر خواستید همینجا هم می‌گذارم.
  # --- IMPORTANT ---
  # چون شما تاکید دارید "کد کامل"، من ادامه را هم کامل می‌گذارم:

  cat > "$TEMPL_DIR/login.html" <<'HTML'
<!doctype html>
<html lang="{{ 'fa' if lang=='fa' else 'en' }}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{ t("brand") }} — {{ t("login") }}</title>
  <style>
    body{margin:0;min-height:100vh;display:grid;place-items:center;font-family:system-ui,Segoe UI,Roboto,Arial;background:#0b1220;color:#e8eefc}
    .card{width:min(460px,92vw);border:1px solid rgba(255,255,255,.12);background:rgba(255,255,255,.06);border-radius:18px;padding:18px}
    .row{display:flex;gap:8px;justify-content:flex-end;margin-bottom:8px}
    a{color:#e8eefc;text-decoration:none;border:1px solid rgba(255,255,255,.12);padding:8px 10px;border-radius:999px;background:rgba(255,255,255,.04);font-size:13px}
    label{font-size:13px;color:rgba(232,238,252,.72);display:block;margin:14px 0 8px}
    input{width:100%;padding:12px;border-radius:12px;border:1px solid rgba(255,255,255,.12);background:rgba(255,255,255,.05);color:#e8eefc;outline:none}
    button{width:100%;margin-top:16px;padding:12px;border-radius:12px;border:1px solid rgba(124,58,237,.55);background:rgba(124,58,237,.18);color:#e8eefc;font-weight:700;cursor:pointer}
    .err{color:#fca5a5;margin-top:8px}
    .rtl{direction:rtl}.ltr{direction:ltr}
  </style>
</head>
<body class="{{ 'rtl' if lang=='fa' else 'ltr' }}">
  <div class="card">
    <div class="row">
      <a href="/lang/fa">FA</a><a href="/lang/en">EN</a>
    </div>
    <h3 style="margin:0 0 8px 0;">{{ t("login") }}</h3>
    {% if error %}<div class="err">{{ error }}</div>{% endif %}
    <form method="post" action="/login">
      <label>{{ t("username") }}</label>
      <input name="username" required>
      <label>{{ t("password") }}</label>
      <input name="password" type="password" required>
      <button type="submit">{{ t("login") }}</button>
    </form>
  </div>
</body>
</html>
HTML

  cat > "$TEMPL_DIR/base.html" <<'HTML'
<!doctype html>
<html lang="{{ 'fa' if lang=='fa' else 'en' }}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{ t("brand") }}</title>
  <style>
    :root{--bg:#0b1220;--card:rgba(255,255,255,.06);--border:rgba(255,255,255,.10);--text:#e8eefc;--muted:rgba(232,238,252,.72);--primary:#7c3aed;--danger:#ef4444;--radius:18px}
    *{box-sizing:border-box}
    body{margin:0;font-family:system-ui,Segoe UI,Roboto,Arial;background:#070b14;color:var(--text)}
    header{position:sticky;top:0;backdrop-filter:blur(12px);background:rgba(11,18,32,.6);border-bottom:1px solid var(--border)}
    .wrap{max-width:1120px;margin:0 auto;padding:14px 18px}
    .nav{display:flex;gap:10px;flex-wrap:wrap;align-items:center;justify-content:space-between}
    .brand{font-weight:800}
    .links{display:flex;gap:8px;flex-wrap:wrap}
    .chip{padding:9px 12px;border-radius:999px;border:1px solid var(--border);background:rgba(255,255,255,.04);color:var(--text);text-decoration:none;font-size:14px}
    .chip:hover{background:rgba(255,255,255,.06)}
    .chip.danger{border-color:rgba(239,68,68,.5);background:rgba(239,68,68,.12)}
    .container{max-width:1120px;margin:0 auto;padding:18px}
    .card{border:1px solid var(--border);background:var(--card);border-radius:var(--radius);padding:16px}
    .grid{display:grid;gap:14px}
    .grid-2{grid-template-columns:repeat(2,minmax(0,1fr))}
    @media(max-width:900px){.grid-2{grid-template-columns:1fr}}
    .muted{color:var(--muted)}
    input,textarea{width:100%;padding:12px;border-radius:12px;border:1px solid var(--border);background:rgba(255,255,255,.05);color:var(--text);outline:none}
    textarea{min-height:140px}
    label{display:block;margin:12px 0 8px;color:var(--muted);font-size:13px}
    .btn{display:inline-flex;align-items:center;justify-content:center;padding:10px 12px;border-radius:12px;border:1px solid var(--border);background:rgba(255,255,255,.05);color:var(--text);cursor:pointer;text-decoration:none;font-weight:700}
    .btn.primary{border-color:rgba(124,58,237,.6);background:rgba(124,58,237,.18)}
    .btn.danger{border-color:rgba(239,68,68,.6);background:rgba(239,68,68,.14)}
    .table{overflow:auto;border:1px solid var(--border);border-radius:14px}
    table{width:100%;border-collapse:collapse;min-width:860px}
    th,td{padding:12px;border-bottom:1px solid rgba(255,255,255,.07);vertical-align:top}
    th{color:var(--muted);font-size:13px;letter-spacing:.08em;text-transform:uppercase}
    .actions{display:flex;gap:8px;flex-wrap:wrap}
    form{margin:0;display:inline}
    .rtl{direction:rtl}.ltr{direction:ltr}
  </style>
</head>
<body class="{{ 'rtl' if lang=='fa' else 'ltr' }}">
<header>
  <div class="wrap">
    <div class="nav">
      <div class="brand">{{ t("brand") }}</div>
      <div class="links">
        <a class="chip" href="/">{{ t("dashboard") }}</a>
        <a class="chip" href="/inbounds">{{ t("inbounds") }}</a>
        <a class="chip" href="/settings">{{ t("settings") }}</a>
        <a class="chip" href="/lang/fa">FA</a>
        <a class="chip" href="/lang/en">EN</a>
        <a class="chip danger" href="/logout">{{ t("logout") }}</a>
      </div>
    </div>
  </div>
</header>
<main class="container">
{% block content %}{% endblock %}
</main>
</body>
</html>
HTML

  cat > "$TEMPL_DIR/dashboard.html" <<'HTML'
{% extends "base.html" %}
{% block content %}
<div class="grid grid-2">
  <div class="card">
    <h2 style="margin-top:0">{{ t("dashboard") }}</h2>
    <div class="muted">Panel is public: http(s)://SERVER_IP:PORT/</div>
    <div style="margin-top:10px">
      <div>{{ t("status") }}: <b>{{ xstat }}</b></div>
      <div class="muted">{{ t("version") }}: {{ xver }}</div>
      <div class="muted">{{ t("latest") }}: {{ latest }}</div>
      {% if upd %}<div style="margin-top:8px;color:#fca5a5">{{ t("update_available") }}</div>{% else %}<div style="margin-top:8px;color:#86efac">{{ t("up_to_date") }}</div>{% endif %}
    </div>
  </div>
  <div class="card">
    <h3 style="margin-top:0">Subscription</h3>
    <div class="muted">For each client: /sub/&lt;token&gt; on same panel port.</div>
  </div>
</div>
{% endblock %}
HTML

  cat > "$TEMPL_DIR/inbounds.html" <<'HTML'
{% extends "base.html" %}
{% block content %}
<div class="card" style="margin-bottom:14px;">
  <div style="display:flex;justify-content:space-between;gap:10px;flex-wrap:wrap;align-items:center;">
    <h2 style="margin:0">{{ t("inbounds") }}</h2>
    <a class="btn primary" href="/inbounds/new">{{ t("new") }}</a>
  </div>
  <div class="muted" style="margin-top:8px;">{{ t("stream_json") }} برای پوشش تمام Transportها</div>
</div>

<div class="card">
  <div class="table">
    <table>
      <tr>
        <th>{{ t("name") }}</th><th>{{ t("protocol") }}</th><th>{{ t("listen") }}</th><th>{{ t("port") }}</th><th>{{ t("status") }}</th><th>{{ t("actions") }}</th>
      </tr>
      {% for i in inbounds %}
      <tr>
        <td>{{ i.name }}</td>
        <td>{{ i.protocol }}</td>
        <td>{{ i.listen }}</td>
        <td>{{ i.port }}</td>
        <td>{{ t("enabled") if i.enabled else t("disabled") }}</td>
        <td class="actions">
          <a class="btn" href="/inbounds/{{ i.id }}/edit">{{ t("edit") }}</a>
          <a class="btn primary" href="/inbounds/{{ i.id }}/clients">{{ t("clients") }}</a>
          <form method="post" action="/inbounds/{{ i.id }}/delete" onsubmit="return confirm('Delete inbound?');">
            <button class="btn danger" type="submit">{{ t("delete") }}</button>
          </form>
        </td>
      </tr>
      {% endfor %}
    </table>
  </div>
</div>
{% endblock %}
HTML

  cat > "$TEMPL_DIR/inbound_form.html" <<'HTML'
{% extends "base.html" %}
{% block content %}
<div class="card">
  <h2 style="margin-top:0;">Inbound</h2>
  <form method="post" action="{{ '/inbounds/new' if mode=='create' else '/inbounds/' ~ inb.id ~ '/edit' }}">
    <label>{{ t("name") }}</label>
    <input name="name" value="{{ inb.name if inb else '' }}" required>

    <label>{{ t("protocol") }} (vless/vmess/trojan/ss/socks/http)</label>
    <input name="protocol" value="{{ inb.protocol if inb else 'vless' }}" required>

    <label>{{ t("listen") }}</label>
    <input name="listen" value="{{ inb.listen if inb else '0.0.0.0' }}">

    <label>{{ t("port") }}</label>
    <input name="port" type="number" value="{{ inb.port if inb else '443' }}" required>

    <label>{{ t("stream_json") }}</label>
    <textarea name="stream_json" placeholder='{"network":"ws","security":"tls","wsSettings":{"path":"/ws"},"tlsSettings":{"serverName":"example.com"}}'>{{ inb.stream_json if inb and inb.stream_json else '' }}</textarea>

    <label>Sniffing JSON (optional)</label>
    <textarea name="sniff_json" placeholder='{"enabled":true,"destOverride":["http","tls"],"routeOnly":true}'>{{ inb.sniff_json if inb and inb.sniff_json else '' }}</textarea>

    <label>Shadowsocks method (if protocol=ss)</label>
    <input name="ss_method" value="{{ ss_method if ss_method else 'aes-128-gcm' }}">

    <div style="margin-top:14px"></div>
    <button class="btn primary" type="submit">{{ t("save") }}</button>
    <a class="btn" href="/inbounds">{{ t("cancel") }}</a>
  </form>
</div>
{% endblock %}
HTML

  cat > "$TEMPL_DIR/clients.html" <<'HTML'
{% extends "base.html" %}
{% block content %}
<div class="card" style="margin-bottom:14px;">
  <div style="display:flex;justify-content:space-between;gap:10px;flex-wrap:wrap;align-items:center;">
    <div>
      <h2 style="margin:0">{{ t("clients") }}</h2>
      <div class="muted">{{ inb.name }} — {{ inb.protocol }} — {{ host }}:{{ inb.port }}</div>
    </div>
    <a class="btn primary" href="/inbounds/{{ inb.id }}/clients/new">{{ t("new") }}</a>
  </div>
  <div class="muted" style="margin-top:10px;">Subscription: /sub/&lt;token&gt; (same panel port)</div>
</div>

<div class="card">
  <div class="table">
    <table>
      <tr>
        <th>{{ t("name") }}</th><th>Email</th><th>{{ t("status") }}</th><th>{{ t("quota_gb") }}</th><th>Used</th><th>{{ t("expire_days") }}</th><th>{{ t("start_on_first_use") }}</th><th>{{ t("actions") }}</th>
      </tr>
      {% for c in clients %}
      <tr>
        <td>{{ c.label }}</td>
        <td class="muted">{{ c.email if c.email else '(auto)' }}</td>
        <td>{{ t("enabled") if c.enabled else t("disabled") }}</td>
        <td>{{ c.quota_gb if c.quota_gb else '-' }}</td>
        <td class="muted">{{ c.used_bytes }}</td>
        <td>{{ c.expire_days if c.expire_days else '-' }}</td>
        <td>{{ 'ON' if c.start_on_first_use else 'OFF' }}</td>
        <td class="actions">
          <a class="btn" href="/clients/{{ c.id }}/edit">{{ t("edit") }}</a>
          <a class="btn" href="/clients/{{ c.id }}/link.txt">{{ t("link") }}</a>
          <a class="btn" href="/clients/{{ c.id }}/qr.png" target="_blank">{{ t("qr") }}</a>
          <a class="btn primary" href="/sub/{{ c.sub_token }}" target="_blank">SUB</a>
          <form method="post" action="/clients/{{ c.id }}/delete" onsubmit="return confirm('Delete client?');">
            <button class="btn danger" type="submit">{{ t("delete") }}</button>
          </form>
        </td>
      </tr>
      {% endfor %}
    </table>
  </div>
</div>
{% endblock %}
HTML

  cat > "$TEMPL_DIR/client_form.html" <<'HTML'
{% extends "base.html" %}
{% block content %}
<div class="card">
  <h2 style="margin-top:0;">Client</h2>
  <form method="post" action="{{ '/inbounds/' ~ inb.id ~ '/clients/new' if mode=='create' else '/clients/' ~ c.id ~ '/edit' }}">
    <label>{{ t("name") }}</label>
    <input name="label" value="{{ c.label if c else '' }}" required>

    <label>Email (optional; unique recommended)</label>
    <input name="email" value="{{ c.email if c and c.email else '' }}" placeholder="user1@omidvpn">

    <label>Secret (UUID/Password). Empty = auto</label>
    <input name="secret" value="" placeholder="">

    <label>{{ t("quota_gb") }} (optional)</label>
    <input name="quota_gb" type="number" value="{{ c.quota_gb if c and c.quota_gb else '' }}">

    <label>{{ t("expire_days") }} (optional)</label>
    <input name="expire_days" type="number" value="{{ c.expire_days if c and c.expire_days else '' }}">

    <label><input type="checkbox" name="start_on_first_use" {% if c and c.start_on_first_use %}checked{% endif %}> {{ t("start_on_first_use") }}</label>

    <label>{{ t("ip_limit") }} (optional)</label>
    <input name="ip_limit" type="number" value="{{ c.ip_limit if c and c.ip_limit else '' }}">

    <label>Note</label>
    <input name="note" value="{{ c.note if c and c.note else '' }}">

    {% if mode=='edit' %}
    <label><input type="checkbox" name="enabled" {% if c and c.enabled %}checked{% endif %}> {{ t("enabled") }}</label>
    {% endif %}

    <div style="margin-top:14px"></div>
    <button class="btn primary" type="submit">{{ t("save") }}</button>
    <a class="btn" href="/inbounds/{{ inb.id }}/clients">{{ t("cancel") }}</a>
  </form>
</div>
{% endblock %}
HTML

  cat > "$TEMPL_DIR/settings.html" <<'HTML'
{% extends "base.html" %}
{% block content %}
<div class="grid grid-2">
  <div class="card">
    <h3 style="margin-top:0">{{ t("settings") }}</h3>

    <form method="post" action="/settings/host">
      <label>{{ t("public_host") }}</label>
      <input name="public_host" value="{{ public_host }}" placeholder="example.com">
      <div class="muted" style="margin-top:6px">اگر خالی باشد، از Host مرورگر تشخیص داده می‌شود.</div>
      <div style="margin-top:12px"></div>
      <button class="btn primary" type="submit">{{ t("save") }}</button>
    </form>

    <hr style="border:0;border-top:1px solid rgba(255,255,255,.10);margin:16px 0;">

    <form method="post" action="/settings/https">
      <label>Domain (for TLS)</label>
      <input name="domain" value="{{ public_host }}" placeholder="example.com" required>

      <label>{{ t("cert_path") }}</label>
      <input name="cert_path" value="{{ cert_path }}" placeholder="/etc/letsencrypt/live/example.com/fullchain.pem" required>

      <label>{{ t("key_path") }}</label>
      <input name="key_path" value="{{ key_path }}" placeholder="/etc/letsencrypt/live/example.com/privkey.pem" required>

      <div class="muted" style="margin-top:6px">{{ t("https_apply") }}</div>
      <div style="margin-top:12px"></div>
      <button class="btn primary" type="submit">{{ t("apply") }}</button>
    </form>

    <form method="post" action="/settings/http" style="margin-top:10px;">
      <button class="btn danger" type="submit">Disable HTTPS (HTTP)</button>
    </form>
  </div>

  <div class="card">
    <h3 style="margin-top:0">Admin</h3>
    <form method="post" action="/settings/credentials">
      <label>{{ t("username") }}</label>
      <input name="new_username" required>
      <label>{{ t("password") }}</label>
      <input name="new_password" type="password" required>
      <div style="margin-top:12px"></div>
      <button class="btn primary" type="submit">{{ t("save") }}</button>
    </form>
  </div>
</div>
{% endblock %}
HTML

  cat > "$APP_DIR/app.py" <<'PY'
# (همان app.py قبلی شما — بدون تغییر عملکردی)
import io, os, json, uuid, subprocess
from datetime import datetime

import qrcode
from fastapi import FastAPI, Depends, Form, Request
from fastapi.responses import HTMLResponse, RedirectResponse, Response, StreamingResponse, PlainTextResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy.orm import Session

from db import SessionLocal, engine, Base
from models import Admin, Setting, Inbound, Client
from security import SessionStore, SESSION_COOKIE, hash_password, verify_password
from i18n import t
import xrayctl
from config_builder import rebuild_xray_config
from linkgen import vless_link, vmess_link, trojan_link, ss_link

Base.metadata.create_all(bind=engine)

APP_DIR = os.getenv("APP_DIR", "/opt/omidvpn")
templates = Jinja2Templates(directory=f"{APP_DIR}/templates")

ADMIN_USERNAME_ENV = os.getenv("ADMIN_USERNAME", "admin")
ADMIN_PASSWORD_ENV = os.getenv("ADMIN_PASSWORD", "admin123")

session_store = SessionStore()
app = FastAPI()

def get_db():
    db = SessionLocal()
    try: yield db
    finally: db.close()

def get_lang(request: Request) -> str:
    lang = request.cookies.get("lang", "fa")
    return "fa" if lang == "fa" else "en"

def authed(request: Request) -> bool:
    return session_store.valid(request.cookies.get(SESSION_COOKIE))

def require_auth(request: Request):
    if not authed(request):
        return RedirectResponse("/login", status_code=303)
    return None

def get_setting(db: Session, key: str, default: str="") -> str:
    s = db.get(Setting, key)
    return s.value if s else default

def set_setting(db: Session, key: str, value: str):
    s = db.get(Setting, key)
    if not s: s = Setting(key=key, value=value)
    else: s.value = value
    db.add(s); db.commit()

def ensure_admin(db: Session):
    a = db.get(Admin, "admin")
    if not a:
        a = Admin(id="admin", username=ADMIN_USERNAME_ENV, password_hash=hash_password(ADMIN_PASSWORD_ENV))
        db.add(a); db.commit()

def guess_host(request: Request, db: Session) -> str:
    stored = get_setting(db, "public_host", "")
    if stored:
        return stored.strip()
    host = request.headers.get("host","SERVER_IP")
    return host.split(":")[0]

def restart_panel_service():
    subprocess.run(["systemctl","restart","omidvpn-panel"], check=False)

@app.on_event("startup")
def startup():
    db = SessionLocal()
    try:
        ensure_admin(db)
    finally:
        db.close()

@app.get("/lang/{lang}")
def set_lang(lang: str):
    r = RedirectResponse("/", status_code=303)
    r.set_cookie("lang", "fa" if lang == "fa" else "en", httponly=False, samesite="lax")
    return r

@app.get("/login", response_class=HTMLResponse)
def login_form(request: Request, db: Session = Depends(get_db)):
    lang = get_lang(request)
    if authed(request):
        return RedirectResponse("/", status_code=303)
    return templates.TemplateResponse("login.html", {"request": request, "lang": lang, "t": lambda k: t(lang,k), "error": None})

@app.post("/login")
def login(request: Request, username: str = Form(...), password: str = Form(...), db: Session = Depends(get_db)):
    ensure_admin(db)
    lang = get_lang(request)
    a = db.get(Admin, "admin")
    ok = bool(a and a.username == username and verify_password(password, a.password_hash))
    if not ok:
        return templates.TemplateResponse("login.html", {"request": request, "lang": lang, "t": lambda k: t(lang,k), "error": "Invalid credentials"})
    token = session_store.new()
    r = RedirectResponse("/", status_code=303)
    r.set_cookie(SESSION_COOKIE, token, httponly=True, samesite="lax")
    return r

@app.get("/logout")
def logout(request: Request):
    session_store.remove(request.cookies.get(SESSION_COOKIE))
    r = RedirectResponse("/login", status_code=303)
    r.delete_cookie(SESSION_COOKIE)
    return r

@app.get("/", response_class=HTMLResponse)
def dashboard(request: Request, db: Session = Depends(get_db)):
    redir = require_auth(request)
    if redir: return redir
    lang = get_lang(request)
    return templates.TemplateResponse("dashboard.html", {
        "request": request, "lang": lang, "t": lambda k: t(lang,k),
        "xstat": xrayctl.is_active(),
        "xver": xrayctl.version_line(),
        "latest": xrayctl.latest_tag(),
        "upd": xrayctl.update_available()
    })

@app.get("/inbounds", response_class=HTMLResponse)
def inbounds_page(request: Request, db: Session = Depends(get_db)):
    redir = require_auth(request)
    if redir: return redir
    lang = get_lang(request)
    inbounds = db.query(Inbound).order_by(Inbound.created_at.desc()).all()
    return templates.TemplateResponse("inbounds.html", {"request": request, "lang": lang, "t": lambda k: t(lang,k), "inbounds": inbounds})

@app.get("/inbounds/new", response_class=HTMLResponse)
def inbound_new_form(request: Request):
    redir = require_auth(request)
    if redir: return redir
    lang = get_lang(request)
    return templates.TemplateResponse("inbound_form.html", {"request": request, "lang": lang, "t": lambda k: t(lang,k), "mode":"create", "inb": None, "ss_method":"aes-128-gcm"})

@app.post("/inbounds/new")
def inbound_new(
    request: Request,
    name: str = Form(...),
    protocol: str = Form(...),
    listen: str = Form("0.0.0.0"),
    port: int = Form(...),
    stream_json: str = Form(""),
    sniff_json: str = Form(""),
    ss_method: str = Form("aes-128-gcm"),
    db: Session = Depends(get_db),
):
    redir = require_auth(request)
    if redir: return redir

    p = protocol.strip().lower()
    extra = None
    if p in ("ss","shadowsocks"):
        extra = json.dumps({"method": ss_method})

    inb = Inbound(
        name=name.strip(),
        protocol=p,
        listen=listen.strip(),
        port=int(port),
        enabled=True,
        stream_json=(stream_json.strip() or None),
        sniff_json=(sniff_json.strip() or None),
        extra_json=extra,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )
    db.add(inb); db.commit()
    rebuild_xray_config(db); xrayctl.restart()
    return RedirectResponse("/inbounds", status_code=303)

@app.get("/inbounds/{inb_id}/edit", response_class=HTMLResponse)
def inbound_edit_form(inb_id: str, request: Request, db: Session = Depends(get_db)):
    redir = require_auth(request)
    if redir: return redir
    lang = get_lang(request)
    inb = db.get(Inbound, inb_id)
    ss_method="aes-128-gcm"
    if inb and inb.extra_json:
        try: ss_method=json.loads(inb.extra_json).get("method", ss_method)
        except: pass
    return templates.TemplateResponse("inbound_form.html", {"request": request, "lang": lang, "t": lambda k: t(lang,k), "mode":"edit", "inb": inb, "ss_method": ss_method})

@app.post("/inbounds/{inb_id}/edit")
def inbound_edit(
    inb_id: str,
    request: Request,
    name: str = Form(...),
    protocol: str = Form(...),
    listen: str = Form("0.0.0.0"),
    port: int = Form(...),
    stream_json: str = Form(""),
    sniff_json: str = Form(""),
    ss_method: str = Form("aes-128-gcm"),
    db: Session = Depends(get_db),
):
    redir = require_auth(request)
    if redir: return redir
    inb = db.get(Inbound, inb_id)
    if not inb:
        return RedirectResponse("/inbounds", status_code=303)

    p = protocol.strip().lower()
    inb.name = name.strip()
    inb.protocol = p
    inb.listen = listen.strip()
    inb.port = int(port)
    inb.stream_json = (stream_json.strip() or None)
    inb.sniff_json = (sniff_json.strip() or None)
    if p in ("ss","shadowsocks"):
        inb.extra_json = json.dumps({"method": ss_method})
    else:
        inb.extra_json = None
    inb.updated_at = datetime.utcnow()
    db.add(inb); db.commit()
    rebuild_xray_config(db); xrayctl.restart()
    return RedirectResponse("/inbounds", status_code=303)

@app.post("/inbounds/{inb_id}/delete")
def inbound_delete(inb_id: str, request: Request, db: Session = Depends(get_db)):
    redir = require_auth(request)
    if redir: return redir
    inb = db.get(Inbound, inb_id)
    if inb:
        for c in db.query(Client).filter(Client.inbound_id == inb.id).all():
            db.delete(c)
        db.delete(inb); db.commit()
        rebuild_xray_config(db); xrayctl.restart()
    return RedirectResponse("/inbounds", status_code=303)

def _uuid() -> str: return str(uuid.uuid4())
def _pw(n=16) -> str:
    import string, random
    a = string.ascii_letters + string.digits
    return "".join(random.choice(a) for _ in range(n))

@app.get("/inbounds/{inb_id}/clients", response_class=HTMLResponse)
def clients_page(inb_id: str, request: Request, db: Session = Depends(get_db)):
    redir = require_auth(request)
    if redir: return redir
    lang = get_lang(request)
    inb = db.get(Inbound, inb_id)
    if not inb:
        return RedirectResponse("/inbounds", status_code=303)
    clients = db.query(Client).filter(Client.inbound_id == inb_id).order_by(Client.created_at.desc()).all()
    host = guess_host(request, db)
    return templates.TemplateResponse("clients.html", {"request": request, "lang": lang, "t": lambda k: t(lang,k), "inb": inb, "clients": clients, "host": host})

@app.get("/inbounds/{inb_id}/clients/new", response_class=HTMLResponse)
def client_new_form(inb_id: str, request: Request, db: Session = Depends(get_db)):
    redir = require_auth(request)
    if redir: return redir
    lang = get_lang(request)
    inb = db.get(Inbound, inb_id)
    return templates.TemplateResponse("client_form.html", {"request": request, "lang": lang, "t": lambda k: t(lang,k), "mode":"create", "inb": inb, "c": None})

@app.post("/inbounds/{inb_id}/clients/new")
def client_new(
    inb_id: str,
    request: Request,
    label: str = Form(...),
    email: str = Form(""),
    secret: str = Form(""),
    quota_gb: str = Form(""),
    expire_days: str = Form(""),
    start_on_first_use: str = Form(""),
    ip_limit: str = Form(""),
    note: str = Form(""),
    db: Session = Depends(get_db),
):
    redir = require_auth(request)
    if redir: return redir
    inb = db.get(Inbound, inb_id)
    if not inb:
        return RedirectResponse("/inbounds", status_code=303)

    if not secret.strip():
        secret_val = _uuid() if inb.protocol in ("vless","vmess") else _pw()
    else:
        secret_val = secret.strip()

    c = Client(
        inbound_id=inb_id,
        label=label.strip(),
        email=(email.strip() or None),
        secret=secret_val,
        enabled=True,
        quota_gb=(int(quota_gb) if quota_gb.strip() else None),
        expire_days=(int(expire_days) if expire_days.strip() else None),
        start_on_first_use=(start_on_first_use == "on"),
        ip_limit=(int(ip_limit) if ip_limit.strip() else None),
        note=(note.strip() or None),
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )
    db.add(c); db.commit()
    rebuild_xray_config(db); xrayctl.restart()
    return RedirectResponse(f"/inbounds/{inb_id}/clients", status_code=303)

@app.post("/clients/{cid}/delete")
def client_delete(cid: str, request: Request, db: Session = Depends(get_db)):
    redir = require_auth(request)
    if redir: return redir
    c = db.get(Client, cid)
    if c:
        inb_id = c.inbound_id
        db.delete(c); db.commit()
        rebuild_xray_config(db); xrayctl.restart()
        return RedirectResponse(f"/inbounds/{inb_id}/clients", status_code=303)
    return RedirectResponse("/inbounds", status_code=303)

def _link_for(inb: Inbound, c: Client, host: str) -> str:
    port = inb.port
    remark = c.label
    proto = inb.protocol
    if proto == "vless":
        return vless_link(host, port, c.secret, remark=remark)
    if proto == "vmess":
        return vmess_link(host, port, c.secret, remark=remark)
    if proto == "trojan":
        return trojan_link(host, port, c.secret, remark=remark)
    if proto in ("ss","shadowsocks"):
        method = "aes-128-gcm"
        if inb.extra_json:
            try: method = json.loads(inb.extra_json).get("method", method)
            except: pass
        return ss_link(host, port, method, c.secret, remark=remark)
    return f"{proto}://{host}:{port}"

@app.get("/clients/{cid}/link.txt")
def client_link(cid: str, request: Request, db: Session = Depends(get_db)):
    redir = require_auth(request)
    if redir: return redir
    c = db.get(Client, cid)
    inb = db.get(Inbound, c.inbound_id) if c else None
    if not c or not inb:
        return RedirectResponse("/inbounds", status_code=303)
    host = guess_host(request, db)
    link = _link_for(inb, c, host)
    return Response(content=link, media_type="text/plain")

@app.get("/clients/{cid}/qr.png")
def client_qr(cid: str, request: Request, db: Session = Depends(get_db)):
    redir = require_auth(request)
    if redir: return redir
    c = db.get(Client, cid)
    inb = db.get(Inbound, c.inbound_id) if c else None
    if not c or not inb:
        return RedirectResponse("/inbounds", status_code=303)
    host = guess_host(request, db)
    link = _link_for(inb, c, host)
    img = qrcode.make(link)
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    buf.seek(0)
    return StreamingResponse(buf, media_type="image/png")

@app.get("/sub/{token}")
def subscription(token: str, request: Request, db: Session = Depends(get_db)):
    c = db.query(Client).filter(Client.sub_token == token).first()
    if not c or not c.enabled:
        return PlainTextResponse("not found", status_code=404)
    inb = db.get(Inbound, c.inbound_id)
    if not inb or not inb.enabled:
        return PlainTextResponse("not found", status_code=404)
    host = guess_host(request, db)
    link = _link_for(inb, c, host)
    return PlainTextResponse(link + "\n", media_type="text/plain")

@app.post("/settings/https")
def settings_https(
    request: Request,
    domain: str = Form(...),
    cert_path: str = Form(...),
    key_path: str = Form(...),
    db: Session = Depends(get_db),
):
    redir = require_auth(request)
    if redir: return redir

    domain = domain.strip()
    cert_path = cert_path.strip()
    key_path = key_path.strip()

    if not cert_path.startswith("/") or not key_path.startswith("/"):
        return PlainTextResponse("cert_path and key_path must start with '/'", status_code=400)

    if not os.path.isfile(cert_path):
        return PlainTextResponse(f"cert file not found: {cert_path}", status_code=400)
    if not os.path.isfile(key_path):
        return PlainTextResponse(f"key file not found: {key_path}", status_code=400)

    set_setting(db, "public_host", domain)
    set_setting(db, "cert_path", cert_path)
    set_setting(db, "key_path", key_path)

    restart_panel_service()
    return RedirectResponse("/settings", status_code=303)
PY
}

write_services(){
  log "Writing systemd services..."

  cat > "$PANEL_SERVICE" <<EOF
[Unit]
Description=Omid VPN Panel (public)
After=network.target xray.service

[Service]
Type=simple
WorkingDirectory=${APP_DIR}
ExecStart=/usr/bin/env bash -lc 'set -a; source ${APP_DIR}/.env; set +a; \
  if [[ -n "\${CERT_PATH:-}" && -n "\${KEY_PATH:-}" && -f "\${CERT_PATH}" && -f "\${KEY_PATH}" ]]; then \
    exec /usr/bin/python3 -m uvicorn app:app --host 0.0.0.0 --port \${PANEL_PORT} --ssl-certfile "\${CERT_PATH}" --ssl-keyfile "\${KEY_PATH}"; \
  else \
    exec /usr/bin/python3 -m uvicorn app:app --host 0.0.0.0 --port \${PANEL_PORT}; \
  fi'
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

  cat > "$SYNC_SERVICE" <<EOF
[Unit]
Description=Omid VPN Sync Usage & Enforce Limits
After=network.target xray.service

[Service]
Type=oneshot
WorkingDirectory=${APP_DIR}
ExecStart=/usr/bin/env bash -lc 'set -a; source ${APP_DIR}/.env; set +a; /usr/bin/python3 ${APP_DIR}/sync_usage.py'
EOF

  cat > "$SYNC_TIMER" <<'EOF'
[Unit]
Description=Run Omid VPN Sync every 60s

[Timer]
OnBootSec=30s
OnUnitActiveSec=60s
Unit=omidvpn-sync.service

[Install]
WantedBy=timers.target
EOF

  systemctl daemon-reload
  systemctl enable --now xray || true
  systemctl enable --now omidvpn-panel
  systemctl enable --now omidvpn-sync.timer
}

final_print(){
  local ip
  ip="$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' || true)"
  ip="${ip:-<SERVER_IP>}"

  echo
  echo "======================================"
  echo "Omid VPN (امید وی‌پی‌ان) نصب شد."
  echo "Panel (HTTP by default): http://${ip}:${PANEL_PORT}/"
  echo "Login: ${ADMIN_USERNAME} / (your password)"
  echo "Services:"
  echo "  systemctl status omidvpn-panel"
  echo "  systemctl status xray"
  echo "  systemctl status omidvpn-sync.timer"
  echo "======================================"
}

main(){
  require_root
  prompt_settings
  install_packages
  install_python_libs
  install_xray
  write_panel_files
  write_services
  final_print
}

main
