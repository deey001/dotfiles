#!/bin/bash

# ==============================================================================
# get_network_status.sh
# ==============================================================================
# Format: Icon $LAN: IP, Icon $VPN IP, Icon WAN: IP
# Caches WAN/ISP results to avoid excessive API calls.
# ==============================================================================

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# ------------------------------------------------------------------------------
# Cache Configuration
# ------------------------------------------------------------------------------
CACHE_FILE="/tmp/tmux_network_cache"
CACHE_MAX_AGE=300  # 5 minutes in seconds

# ------------------------------------------------------------------------------
# Icon Definitions (Nerd Fonts - literal Unicode characters)
# ------------------------------------------------------------------------------
ICON_LAN="󰌘"
ICON_VPN=""
ICON_WAN=""
ICON_OFFLINE=""

# ------------------------------------------------------------------------------
# Network Information Retrieval
# ------------------------------------------------------------------------------

# 1. Get Local IP (LAN)
LOCAL_IP=""
if command -v ip >/dev/null 2>&1; then
    LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+')
    if [ -z "$LOCAL_IP" ]; then
        LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')
    fi
fi
# macOS fallback
if [ -z "$LOCAL_IP" ] && command -v ipconfig >/dev/null 2>&1; then
    LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
fi
# Linux fallback
if [ -z "$LOCAL_IP" ] && command -v hostname >/dev/null 2>&1; then
    LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
fi

# 2. Get VPN IP (Tunnel Interface)
VPN_IP=""
if command -v ip >/dev/null 2>&1; then
    VPN_IP=$(ip addr show tun0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
    if [ -z "$VPN_IP" ]; then
        VPN_IP=$(ip addr show ppp0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
    fi
fi

# 3. Get WAN IP and ISP (cached to avoid excessive API calls)
WAN_IP=""
ISP=""

use_cache=false
if [ -f "$CACHE_FILE" ]; then
    cache_mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null)
    if [ -n "$cache_mtime" ]; then
        cache_age=$(( $(date +%s) - cache_mtime ))
        if [ "$cache_age" -lt "$CACHE_MAX_AGE" ]; then
            use_cache=true
        fi
    fi
fi

if [ "$use_cache" = true ]; then
    WAN_IP=$(sed -n '1p' "$CACHE_FILE")
    ISP=$(sed -n '2p' "$CACHE_FILE")
else
    if ping -c 1 -W 1 8.8.8.8 &>/dev/null 2>&1 || ping -c 1 -t 1 8.8.8.8 &>/dev/null 2>&1; then
        WAN_IP=$(curl -s --connect-timeout 2 --max-time 3 ifconfig.me 2>/dev/null)
        if [ -z "$WAN_IP" ]; then
            WAN_IP=$(curl -s --connect-timeout 2 --max-time 3 icanhazip.com 2>/dev/null)
        fi
        if [ -z "$WAN_IP" ]; then
            WAN_IP=$(curl -s --connect-timeout 2 --max-time 3 api.ipify.org 2>/dev/null)
        fi

        # Get ISP info via JSON API
        if [ -n "$WAN_IP" ]; then
            ISP_JSON=$(curl -s --connect-timeout 2 --max-time 3 "http://ip-api.com/json/${WAN_IP}?fields=isp" 2>/dev/null)
            if [ -n "$ISP_JSON" ]; then
                # Use jq if available, otherwise grep+sed to decode JSON unicode escapes
                if command -v jq >/dev/null 2>&1; then
                    ISP=$(echo "$ISP_JSON" | jq -r '.isp // empty')
                else
                    ISP=$(echo "$ISP_JSON" | grep -o '"isp":"[^"]*"' | cut -d'"' -f4 | sed 's/\\u0026/\&/g; s/\\u003c/</g; s/\\u003e/>/g')
                fi
            fi
            if [ -z "$ISP" ]; then
                ISP=$(curl -s --connect-timeout 2 --max-time 3 "https://ipapi.co/${WAN_IP}/org/" 2>/dev/null)
            fi
        fi
        printf '%s\n%s\n' "$WAN_IP" "$ISP" > "$CACHE_FILE" 2>/dev/null
    fi
fi

# Shorten ISP name to a clean label
shorten_isp() {
    local raw="$1"
    case "$raw" in
        *Comcast*|*Xfinity*)     echo "Comcast" ;;
        *Verizon*)               echo "Verizon" ;;
        *"AT&T"*|*ATT*)          echo "AT&T" ;;
        *Spectrum*|*Charter*)    echo "Spectrum" ;;
        *Google*|*GFiber*)       echo "Google" ;;
        *T-Mobile*)              echo "T-Mobile" ;;
        *Cox*)                   echo "Cox" ;;
        *CenturyLink*|*Lumen*)   echo "CenturyLink" ;;
        *Frontier*)              echo "Frontier" ;;
        *Optimum*|*Altice*)      echo "Optimum" ;;
        *)                       echo "$raw" | sed 's/,.*//; s/ LLC//; s/ Inc//; s/ Corp//; s/ Enterprises//' ;;
    esac
}

ISP_SHORT=$(shorten_isp "$ISP")

# ------------------------------------------------------------------------------
# Status Construction
# ------------------------------------------------------------------------------

# Plain mode for catppuccin tmux plugin (no tmux color codes)
PLAIN_MODE=false
if [ "$1" = "--plain" ]; then
    PLAIN_MODE=true
fi

OUTPUT=""

if [ "$PLAIN_MODE" = true ]; then
    # Compact plain text for catppuccin module
    PARTS=""
    if [ -n "$LOCAL_IP" ]; then
        PARTS="${LOCAL_IP}"
    fi
    if [ -n "$VPN_IP" ]; then
        PARTS="${PARTS:+$PARTS  }VPN: ${VPN_IP}"
    fi
    if [ -n "$WAN_IP" ] && [ -n "$ISP_SHORT" ]; then
        PARTS="${PARTS:+$PARTS  }${ISP_SHORT}: ${WAN_IP}"
    elif [ -n "$WAN_IP" ]; then
        PARTS="${PARTS:+$PARTS  }WAN: ${WAN_IP}"
    else
        PARTS="${PARTS:+$PARTS  }Offline"
    fi
    echo "$PARTS"
else
    # Formatted output for manual tmux status bar
    if [ -n "$LOCAL_IP" ]; then
        OUTPUT="#[fg=green]${ICON_LAN} LAN: ${LOCAL_IP}"
    else
        OUTPUT="#[fg=red]${ICON_LAN} LAN: N/A"
    fi

    if [ -n "$VPN_IP" ]; then
        OUTPUT="${OUTPUT} #[fg=yellow]${ICON_VPN} VPN: ${VPN_IP}"
    fi

    if [ -n "$WAN_IP" ] && [ -n "$ISP_SHORT" ]; then
        OUTPUT="${OUTPUT} #[fg=cyan]${ICON_WAN} ${ISP_SHORT}: ${WAN_IP}"
    elif [ -n "$WAN_IP" ]; then
        OUTPUT="${OUTPUT} #[fg=cyan]${ICON_WAN} WAN: ${WAN_IP}"
    else
        OUTPUT="${OUTPUT} #[fg=red]${ICON_OFFLINE} Offline"
    fi

    echo "$OUTPUT"
fi
