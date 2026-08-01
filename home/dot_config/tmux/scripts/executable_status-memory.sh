#!/bin/sh

free=$(memory_pressure -Q 2>/dev/null | awk '/free percentage/ { gsub(/%/, "", $5); print $5 }')
[ -n "$free" ] && printf 'RAM %s%%' "$((100 - free))"
