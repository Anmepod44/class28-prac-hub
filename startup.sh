#!/usr/bin/env bash
# Replaces tomcat-users.xml, disables the remote-access Valve on the
# Manager and Host Manager apps, and restarts Tomcat.
# Usage: sudo bash setup-tomcat.sh   (optional: TOMCAT_HOME=/path sudo -E bash setup-tomcat.sh)

set -euo pipefail

TOMCAT_HOME="${TOMCAT_HOME:-/opt/tomcat}"
STAMP="$(date +%Y%m%d-%H%M%S)"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo bash $0" >&2
  exit 1
fi

if [[ ! -d "$TOMCAT_HOME/conf" ]]; then
  echo "Tomcat not found at $TOMCAT_HOME (set TOMCAT_HOME)" >&2
  exit 1
fi

# 1. tomcat-users.xml
USERS="$TOMCAT_HOME/conf/tomcat-users.xml"
[[ -f "$USERS" ]] && cp "$USERS" "$USERS.bak.$STAMP"

cat > "$USERS" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users>
  <!-- Roles -->
  <role rolename="manager-gui"/>
  <role rolename="manager-script"/>
  <role rolename="admin-gui"/>
  <role rolename="admin-script"/>

  <!-- User -->
  <user username="deployer" password="StrongPass!" roles="manager-gui,manager-script,admin-gui,admin-script"/>
</tomcat-users>
EOF
echo "Wrote $USERS"

# 2. Comment out the Valve in manager and host-manager
for app in manager host-manager; do
  CTX="$TOMCAT_HOME/webapps/$app/META-INF/context.xml"
  if [[ ! -f "$CTX" ]]; then
    echo "Skipping $app (no $CTX)"
    continue
  fi
  if grep -q "disabled by setup-tomcat" "$CTX"; then
    echo "Valve already disabled in $app"
    continue
  fi
  cp "$CTX" "$CTX.bak.$STAMP"
  perl -0pi -e 's/(<Valve\s+className="org\.apache\.catalina\.valves\.Remote(?:Addr|CIDR)Valve"[^>]*?\/>)/<!-- disabled by setup-tomcat: $1 -->/gs' "$CTX"
  echo "Disabled Valve in $CTX"
done

# 3. Restart Tomcat
echo "Restarting Tomcat..."
"$TOMCAT_HOME/bin/shutdown.sh" || true
sleep 5
"$TOMCAT_HOME/bin/startup.sh"
sleep 8

# 4. Quick check (401 = Manager is up and asking for login)
CODE="$(curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/manager/html || true)"
echo "GET /manager/html -> HTTP $CODE (401 means it is up and asking for login)"
