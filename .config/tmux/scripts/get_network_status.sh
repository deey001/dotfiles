#!/bin/bash

# ==============================================================================
# get_network_status.sh
# ==============================================================================
# Format: Icon $LAN: IP, Icon $VPN IP, Icon WAN: IP
# ==============================================================================

# Explicitly set PATH to ensure tools are found (crucial for cron/tmux)
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# ------------------------------------------------------------------------------
# Icon Definitions (Nerd Fonts)
# ------------------------------------------------------------------------------
ICON_LAN="󰌘"            # 󰌘 nf-md-lan_connect
ICON_VPN="\uf023"       #   Lock/Secure
ICON_WAN="\uf0ac"       #   Globe/World
ICON_OFFLINE="\uf127"   #   Broken chain/Offline

# ISP Specific Icons
ICON_COMCAST="\uf85a"   # Comcast/Xfinity
ICON_VERIZON="\ue943"   # Verizon check
ICON_ATT="\uf080"       # AT&T signal
ICON_GOOGLE="\uf1a0"    # Google
ICON_TMOBILE="\uf129"   # T-Mobile info
ICON_COX="\uf85c"       # Cox

# ------------------------------------------------------------------------------
# Network Information Retrieval
# ------------------------------------------------------------------------------

# 1. Get Local IP (LAN)
# Try `ip route` first (Linux standard)
if command -v ip >/dev/null 2>&1; then
    LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+')
    # Fallback to awk if grep -P is not available
    if [ -z "$LOCAL_IP" ]; then
        LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')
    fi
fi

# Fallback to `hostname -I` (common on many distros)
if [ -z "$LOCAL_IP" ] && command -v hostname >/dev/null 2>&1; then
    LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
fi

# 2. Get VPN IP (Tunnel Interface)
if command -v ip >/dev/null 2>&1; then
    VPN_IP=$(ip addr show tun0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
    if [ -z "$VPN_IP" ]; then
        VPN_IP=$(ip addr show ppp0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
    fi
fi

# 3. Get WAN IP and ISP (Only if online)
WAN_IP=""
ISP=""
ISP_ICON="$ICON_WAN"

# Check connectivity with short timeout (1 second)
if ping -c 1 -W 1 8.8.8.8 &> /dev/null; then
    WAN_IP=$(curl -s --connect-timeout 2 ifconfig.me)
    if [ -z "$WAN_IP" ]; then
         WAN_IP=$(curl -s --connect-timeout 2 icanhazip.com)
    fi
    
    # Get ISP name (Org)
    ISP=$(curl -s --connect-timeout 2 https://ipapi.co/org/ 2>/dev/null)
    
    # Map ISP to Icon
    case "$ISP" in
        *Comcast*|*Xfinity*)     ISP_ICON="$ICON_COMCAST" ;;
        *Verizon*)               ISP_ICON="$ICON_VERIZON" ;;
        *AT\&T*|*ATT*)           ISP_ICON="$ICON_ATT" ;;
        *Spectrum*|*Charter*)    ISP_ICON="$ICON_WAN" ;;
        *Google*)                ISP_ICON="$ICON_GOOGLE" ;;
        *T-Mobile*)              ISP_ICON="$ICON_TMOBILE" ;;
        *Cox*)                   ISP_ICON="$ICON_COX" ;;
    esac
else
    # If ping failed, we might still want to check if we have WAN IP causing the issue? 
    # Usually NO, just mark offline.
    WAN_IP="" 
    ISP_ICON="$ICON_OFFLINE"
fi

# ------------------------------------------------------------------------------
# Status Construction
# ------------------------------------------------------------------------------

OUTPUT=""

# Format: LAN
if [ -n "$LOCAL_IP" ]; then
    OUTPUT=" #[fg=green] ${ICON_LAN} LAN: ${LOCAL_IP}"
else
    OUTPUT=" #[fg=red] ${ICON_LAN} LAN: Disconnected"
fi

# Format: VPN
if [ -n "$VPN_IP" ]; then
    OUTPUT="${OUTPUT} #[fg=yellow]${ICON_VPN} VPN: ${VPN_IP}"
fi

# Format: WAN
if [ -n "$WAN_IP" ]; then
    OUTPUT="${OUTPUT} #[fg=cyan]${ISP_ICON} WAN: ${WAN_IP}"
elif [ "$ISP_ICON" == "$ICON_OFFLINE" ]; then
     # Use a distinct color for Offline status if desired, or skip WAN entirely
     OUTPUT="${OUTPUT} #[fg=red]${ISP_ICON} Offline"
fi

echo -e "$OUTPUT"
