#!/bin/bash

# ==============================================================================
# get_network_status.sh
# ==============================================================================
# This script retrieves network information (LAN, VPN, WAN) and formats it
# for the Tmux status bar using Nerd Font icons.
#
# Format: Icon $LAN: IP, Icon $VPN IP, Icon WAN: IP
# ==============================================================================

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
# Uses `ip route` to find the source address for the default route.
LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}')

# 2. Get VPN IP (Tunnel Interface)
# Checks for common VPN interfaces like tun0 or ppp0.
VPN_IP=$(ip addr show tun0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
if [ -z "$VPN_IP" ]; then
    VPN_IP=$(ip addr show ppp0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
fi

# 3. Get WAN IP and ISP (Only if online)
# Set a short timeout to prevent blocking if offline.
WAN_IP=""
ISP=""
ISP_ICON="$ICON_WAN"

# Check connectivity first to avoid long timeouts
if ping -c 1 8.8.8.8 &> /dev/null; then
    WAN_IP=$(curl -s --connect-timeout 2 ifconfig.me)
    # Get ISP name (Org) from ipapi.co
    ISP=$(curl -s --connect-timeout 2 https://ipapi.co/org/ 2>/dev/null)
    
    # Map ISP to Icon
    case "$ISP" in
        *Comcast*|*Xfinity*)     ISP_ICON="$ICON_COMCAST" ;;
        *Verizon*)               ISP_ICON="$ICON_VERIZON" ;;
        *AT\&T*|*ATT*)           ISP_ICON="$ICON_ATT" ;;
        *Spectrum*|*Charter*)    ISP_ICON="$ICON_WAN" ;; # Default to WAN for others for now
        *Google*)                ISP_ICON="$ICON_GOOGLE" ;;
        *T-Mobile*)              ISP_ICON="$ICON_TMOBILE" ;;
        *Cox*)                   ISP_ICON="$ICON_COX" ;;
    esac
else
    WAN_IP="Offline"
    ISP_ICON="$ICON_OFFLINE"
fi

# ------------------------------------------------------------------------------
# Status Construction
# ------------------------------------------------------------------------------

OUTPUT=""

# Format: LAN
if [ -n "$LOCAL_IP" ]; then
    # Green for LAN
    OUTPUT="#[fg=green]${ICON_LAN} LAN: ${LOCAL_IP}"
else
    OUTPUT="#[fg=red]${ICON_LAN} LAN: Disconnected"
fi

# Format: VPN (Only if connected)
if [ -n "$VPN_IP" ]; then
    # Yellow for VPN
    OUTPUT="${OUTPUT}  #[fg=yellow]${ICON_VPN} VPN: ${VPN_IP}"
fi

# Format: WAN
if [ -n "$WAN_IP" ]; then
    # Cyan for WAN
    OUTPUT="${OUTPUT}  #[fg=cyan]${ISP_ICON} WAN: ${WAN_IP}"
fi

echo -e "$OUTPUT"
