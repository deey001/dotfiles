#!/bin/bash
# Get ISP name and return appropriate icon

ISP=$(curl -s https://ipapi.co/json/ | grep -o '"org":"[^"]*"' | cut -d'"' -f4)

# Map ISP to icons
case "$ISP" in
    *Comcast*|*Xfinity*)
        echo " "  # Comcast icon
        ;;
    *Verizon*)
        echo " "  # Verizon icon
        ;;
    *AT\&T*|*ATT*)
        echo "󰈀 "  # AT&T icon
        ;;
    *Spectrum*|*Charter*)
        echo " "  # Spectrum icon
        ;;
    *Google*)
        echo "󰊭 "  # Google Fiber icon
        ;;
    *T-Mobile*)
        echo " "  # T-Mobile icon
        ;;
    *Cox*)
        echo " "  # Cox icon
        ;;
    *)
        echo " "  # Generic globe icon
        ;;
esac
