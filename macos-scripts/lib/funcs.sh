#!/usr/bin/env bash

autoload -Uz colors && colors

function log() { print -P "%F{green}[INFO]%f $*"; }
function warn() { print -P "%F{yellow}[WARN]%f $*"; }
function err() { print -P "%F{red}[ERROR]%f $*"; }
function diff() { print -P "%F{blue}[DIFF]%f $*"; }

function audit_all() {
  for section in "./sections/"*.sh; do
    audit_section "$(basename "${section}" .sh)"
    bash "${section}"
  done
}

function audit_section() {
  local section="$1"
  log "--- Auditing: $section"
  # Load expected values from config.yml (use yq or grep)
  # Compare with `defaults read`
  # Print diff nicely
}

function keep_sudo_alive() {
  sudo -v
  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done 2>/dev/null &
}

function check_command() {
  command -v "$1" >/dev/null 2>&1
}
