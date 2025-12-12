#!/bin/bash
# Network status script with icons for tmux status bar

# Nerd Font Icons
ICON_LAN=""      # LAN/Network icon
ICON_VPN=""      # VPN/Shield icon
ICON_GLOBE=""    # Generic globe for unknown ISP

# Get local IP
LOCAL_IP=$(ip route get 1.2.3.4 2>/dev/null | awk '{print $7}')

# Get VPN IP (check tun0 and ppp0)
VPN_IP=$(ip addr show tun0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
if [ -z "$VPN_IP" ]; then
    VPN_IP=$(ip addr show ppp0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
fi

# Get WAN IP and ISP
WAN_IP=$(curl -s --connect-timeout 2 ifconfig.me)
ISP=$(curl -s --connect-timeout 2 https://ipapi.co/org/ 2>/dev/null)

# Determine ISP icon
ISP_ICON="$ICON_GLOBE"
case "$ISP" in
    *Comcast*|*Xfinity*)     ISP_ICON="" ;;
    *Verizon*)               ISP_ICON="" ;;
    *AT\&T*|*ATT*)          ISP_ICON="󰈀" ;;
    *Spectrum*|*Charter*)    ISP_ICON="" ;;
    *Google*)                ISP_ICON="󰊭" ;;
    *T-Mobile*)              ISP_ICON="" ;;
    *Cox*)                   ISP_ICON="" ;;
esac

# Build output
OUTPUT=""

# LAN (always show if available)
if [ -n "$LOCAL_IP" ]; then
    OUTPUT="${OUTPUT}#[fg=green]\uf817 ${LOCAL_IP} "
fi

# VPN (only show if connected)
if [ -n "$VPN_IP" ]; then
    OUTPUT="${OUTPUT}#[fg=yellow]\uf023 ${VPN_IP} "
fi

# WAN (always show if available)
if [ -n "$WAN_IP" ]; then
    OUTPUT="${OUTPUT}#[fg=cyan]WAN: ${ISP_ICON} ${WAN_IP}"
fi

echo "$OUTPUT"
