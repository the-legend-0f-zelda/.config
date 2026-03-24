#!/bin/bash
REGION=$(slurp)
if [ -n "$REGION" ]; then
    FILE=~/Pictures/$(date +'%Y%m%d_%H%M%S').png
    grim -g "$REGION" "$FILE"
    wl-copy < "$FILE"
fi
