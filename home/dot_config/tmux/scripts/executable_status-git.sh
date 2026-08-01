#!/bin/sh

branch=$(git -C "$1" symbolic-ref --quiet --short HEAD 2>/dev/null) || exit 0
printf '#[fg=#5f87d7]│  #[fg=#87afff]git:%s  ' "$branch"
