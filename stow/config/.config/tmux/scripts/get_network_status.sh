#!/bin/bash

# ==============================================================================
# get_network_status.sh — Tmux Status Bar Network Info
# ==============================================================================
# Displays LAN IP, VPN IP (if connected), and WAN IP + ISP name in the tmux
# status bar. Caches WAN/ISP results to avoid hammering external APIs.
#
# USAGE:
#   bash get_network_status.sh           → tmux-formatted output (with #[fg=...] color codes)
#   bash get_network_status.sh --plain   → plain text with Nerd Font icons (for catppuccin pills)
#
# OUTPUT FORMAT:
#   Icon LAN: 192.168.1.x  Icon VPN: 10.x.x.x  Icon ISP: WAN_IP
#
# CALLED BY:
#   .tmux.conf → status-right → #(bash ~/.config/tmux/scripts/get_network_status.sh --plain)
#   Runs every `status-interval` seconds (default 60s in .tmux.conf)
#
# DEPENDENCIES:
#   Required: curl (for WAN IP lookup), ping (for connectivity check)
#   Optional: ip (Linux), ipconfig (macOS), hostname, jq (for ISP JSON parsing)
#   Nerd Fonts: Icons require a Nerd Font patched terminal font
#
# ERROR HANDLING:
#   - Each network lookup has independent fallbacks (ip → ipconfig → hostname)
#   - WAN IP tries 3 APIs sequentially (ifconfig.me → icanhazip.com → api.ipify.org)
#   - ISP lookup tries ip-api.com then ipapi.co as fallback
#   - All curl calls have 2s connect timeout + 3s max time to prevent status bar stalls
#   - If connectivity check (ping 8.8.8.8) fails, shows "Offline" instead
#
# CACHING:
#   - WAN IP and ISP are cached in /tmp/tmux_network_cache for 5 minutes
#   - Cache uses file mtime with cross-platform stat (GNU -c %Y / BSD -f %m)
#   - Avoids rate-limiting on free IP lookup APIs
# ==============================================================================

# Force a clean PATH so this script works reliably when invoked by tmux
# (tmux may not inherit the user's full PATH)
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# ------------------------------------------------------------------------------
# Cache Configuration
# ------------------------------------------------------------------------------
# Cache file stores WAN IP (line 1) and ISP name (line 2)
CACHE_FILE="/tmp/tmux_network_cache"
# Refresh every 5 minutes — balances freshness with API rate limits
CACHE_MAX_AGE=300

# ------------------------------------------------------------------------------
# Icon Definitions (Nerd Fonts - literal Unicode characters)
# ------------------------------------------------------------------------------
# These require a Nerd Font installed and configured in your terminal
ICON_LAN="󰌘"       # nf-md-lan (local network)
ICON_VPN=""        # nf-fa-shield (VPN/security)
ICON_WAN=""        # nf-fa-globe (internet/WAN)
ICON_OFFLINE=""    # nf-fa-chain_broken (no connectivity)

# ------------------------------------------------------------------------------
# Network Information Retrieval
# ------------------------------------------------------------------------------

# 1. Get Local IP (LAN)
# Try `ip route` first (Linux), then `ipconfig` (macOS), then `hostname -I` (fallback)
LOCAL_IP=""
if command -v ip >/dev/null 2>&1; then
    # Ask the kernel which source IP would be used to reach 1.1.1.1
    # This reliably gives the primary LAN IP even with multiple interfaces
    LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+')
    if [ -z "$LOCAL_IP" ]; then
        # Fallback: some systems (e.g., BusyBox) lack grep -P
        LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')
    fi
fi
# macOS fallback — try en0 (WiFi) then en1 (Ethernet)
if [ -z "$LOCAL_IP" ] && command -v ipconfig >/dev/null 2>&1; then
    LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
fi
# Final fallback — hostname -I works on most Linux distros
if [ -z "$LOCAL_IP" ] && command -v hostname >/dev/null 2>&1; then
    LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
fi

# 2. Get VPN IP (Tunnel Interface)
# Checks tun0 (OpenVPN/WireGuard) and ppp0 (PPTP/L2TP) interfaces
VPN_IP=""
if command -v ip >/dev/null 2>&1; then
    VPN_IP=$(ip addr show tun0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
    if [ -z "$VPN_IP" ]; then
        VPN_IP=$(ip addr show ppp0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
    fi
fi

# 3. Get WAN IP and ISP (cached to avoid hitting API rate limits)
WAN_IP=""
ISP=""

# Check if we have a fresh cache (younger than CACHE_MAX_AGE seconds)
use_cache=false
if [ -f "$CACHE_FILE" ]; then
    # Cross-platform stat: GNU uses -c %Y, BSD/macOS uses -f %m
    cache_mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null)
    if [ -n "$cache_mtime" ]; then
        cache_age=$(( $(date +%s) - cache_mtime ))
        if [ "$cache_age" -lt "$CACHE_MAX_AGE" ]; then
            use_cache=true
        fi
    fi
fi

if [ "$use_cache" = true ]; then
    # Read cached WAN IP and ISP from file
    WAN_IP=$(sed -n '1p' "$CACHE_FILE")
    ISP=$(sed -n '2p' "$CACHE_FILE")
else
    # Verify internet connectivity with a quick ping before making API calls
    # Uses both -W (GNU timeout) and -t (BSD timeout) for cross-platform support
    if ping -c 1 -W 1 8.8.8.8 &>/dev/null 2>&1 || ping -c 1 -t 1 8.8.8.8 &>/dev/null 2>&1; then
        # Try multiple WAN IP services in order (redundancy against downtime)
        WAN_IP=$(curl -s --connect-timeout 2 --max-time 3 ifconfig.me 2>/dev/null)
        if [ -z "$WAN_IP" ]; then
            WAN_IP=$(curl -s --connect-timeout 2 --max-time 3 icanhazip.com 2>/dev/null)
        fi
        if [ -z "$WAN_IP" ]; then
            WAN_IP=$(curl -s --connect-timeout 2 --max-time 3 api.ipify.org 2>/dev/null)
        fi

        # Get ISP info via JSON API (ip-api.com — free, no API key needed)
        if [ -n "$WAN_IP" ]; then
            ISP_JSON=$(curl -s --connect-timeout 2 --max-time 3 "http://ip-api.com/json/${WAN_IP}?fields=isp" 2>/dev/null)
            if [ -n "$ISP_JSON" ]; then
                # Use jq if available for reliable JSON parsing; otherwise use grep+sed
                # The sed handles common JSON unicode escapes (\u0026 → &, etc.)
                if command -v jq >/dev/null 2>&1; then
                    ISP=$(echo "$ISP_JSON" | jq -r '.isp // empty')
                else
                    ISP=$(echo "$ISP_JSON" | grep -o '"isp":"[^"]*"' | cut -d'"' -f4 | sed 's/\\u0026/\&/g; s/\\u003c/</g; s/\\u003e/>/g')
                fi
            fi
            # Fallback ISP lookup if ip-api.com returned nothing
            if [ -z "$ISP" ]; then
                ISP=$(curl -s --connect-timeout 2 --max-time 3 "https://ipapi.co/${WAN_IP}/org/" 2>/dev/null)
            fi
        fi
        # Write results to cache file (WAN IP on line 1, ISP on line 2)
        printf '%s\n%s\n' "$WAN_IP" "$ISP" > "$CACHE_FILE" 2>/dev/null
    fi
fi

# Shorten ISP name to a clean, recognizable label for the status bar
# Strips legal suffixes (LLC, Inc, Corp) and matches common US ISPs
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

# Plain mode (--plain): outputs compact text with Nerd Font icons only,
# suitable for embedding inside catppuccin tmux pills that apply their own colors.
# Default mode: outputs text with tmux color codes (#[fg=...]) for direct use.
PLAIN_MODE=false
if [ "$1" = "--plain" ]; then
    PLAIN_MODE=true
fi

OUTPUT=""

if [ "$PLAIN_MODE" = true ]; then
    # Compact text with icons for catppuccin module
    PARTS=""
    if [ -n "$LOCAL_IP" ]; then
        PARTS="${ICON_LAN} ${LOCAL_IP}"
    fi
    if [ -n "$VPN_IP" ]; then
        PARTS="${PARTS:+$PARTS  }${ICON_VPN} VPN: ${VPN_IP}"
    fi
    if [ -n "$WAN_IP" ] && [ -n "$ISP_SHORT" ]; then
        PARTS="${PARTS:+$PARTS  }${ICON_WAN} ${ISP_SHORT}: ${WAN_IP}"
    elif [ -n "$WAN_IP" ]; then
        PARTS="${PARTS:+$PARTS  }${ICON_WAN} WAN: ${WAN_IP}"
    else
        PARTS="${PARTS:+$PARTS  }${ICON_OFFLINE} Offline"
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
