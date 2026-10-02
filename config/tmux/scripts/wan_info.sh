#!/bin/bash
# wan_info.sh — Cache-backed WAN IP and ISP lookup for tmux status bar
#
# USAGE:
#   wan_info.sh ip   → public IP address
#   wan_info.sh isp  → short ISP name (default)
#
# CACHING: Results cached in ~/.cache/tmux/wan_info.json for 5 minutes.

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/tmux/wan_info.json"
CACHE_MAX_AGE=300  # 5 minutes

mkdir -p "$(dirname "$CACHE_FILE")"

# Refresh cache if missing or stale
if [[ ! -f "$CACHE_FILE" ]]; then
    MTIME=0
else
    MTIME=$(stat -L --format %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
fi

if (( $(date +%s) - MTIME > CACHE_MAX_AGE )); then
    curl -sf --connect-timeout 3 --max-time 5 https://ifconfig.co/json -o "$CACHE_FILE" 2>/dev/null
fi

[[ ! -f "$CACHE_FILE" ]] && exit 0

shorten_isp() {
    case "$1" in
        *ATT*|*"AT&T"*)  echo "AT&T" ;;
        *Xfinity*)        echo "Xfinity" ;;
        *Comcast*)        echo "Comcast" ;;
        *Verizon*)        echo "Verizon" ;;
        *Spectrum*)       echo "Spectrum" ;;
        *Google*)         echo "Google" ;;
        *T-Mobile*)       echo "T-Mobile" ;;
        *Cox*)            echo "Cox" ;;
        *Frontier*)       echo "Frontier" ;;
        *CenturyLink*|*Lumen*) echo "CenturyLink" ;;
        *MIAMI-DADE*|*"Miami-Dade"*) echo "MDC" ;;
        *)  echo "$1" | sed 's/AS[0-9]* //; s/ LLC//; s/ Inc//; s/ Corp//' | cut -c1-24 ;;
    esac
}

case "${1:-isp}" in
    ip)
        grep -o '"ip": "[^"]*' "$CACHE_FILE" | grep -o '[^"]*$'
        ;;
    isp)
        ORG=$(grep -o '"asn_org": "[^"]*' "$CACHE_FILE" | grep -o '[^"]*$')
        shorten_isp "$ORG"
        ;;
esac
