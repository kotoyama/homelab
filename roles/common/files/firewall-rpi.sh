#!/usr/bin/env bash
set -euo pipefail

IPT="$(command -v iptables)"
IP6="$(command -v ip6tables)"
WAN_IF="$(ip -o -4 route show default | awk '{print $5; exit}')"
[ -n "$WAN_IF" ] || { echo "no default route, aborting" >&2; exit 1; }

ensure_chain() {
  "$1" -L DOCKER-USER -n >/dev/null 2>&1 || "$1" -N DOCKER-USER
}

ensure_chain "$IPT"
ensure_chain "$IP6"

set_container_policy() {
  local bin="$1" net="$2" lo="$3"
  "$bin" -F DOCKER-USER
  "$bin" -A DOCKER-USER -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  "$bin" -A DOCKER-USER -s "$net" -j ACCEPT
  "$bin" -A DOCKER-USER -p tcp --dport 53 -j ACCEPT
  "$bin" -A DOCKER-USER -p udp --dport 53 -j ACCEPT
  "$bin" -A DOCKER-USER -s "$lo" -j ACCEPT
  "$bin" -A DOCKER-USER -i "$WAN_IF" -j DROP
}

set_container_policy "$IPT" 100.64.0.0/10 127.0.0.0/8
set_container_policy "$IP6" fd7a:115c:a1e0::/48 ::1/128

ensure_input_rule() {
  local bin="$1" pos="$2"
  shift 2
  if ! "$bin" -C INPUT "$@" 2>/dev/null; then
    "$bin" -I INPUT "$pos" "$@"
  fi
}

ensure_input_rule "$IPT" 1 -i lo -j ACCEPT
ensure_input_rule "$IPT" 2 -i tailscale0 -j ACCEPT
ensure_input_rule "$IPT" 3 -p tcp --dport 22 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
ensure_input_rule "$IPT" 4 -p tcp --dport 22 -j DROP
ensure_input_rule "$IP6" 1 -i lo -j ACCEPT
ensure_input_rule "$IP6" 2 -i tailscale0 -j ACCEPT
ensure_input_rule "$IP6" 3 -i "$WAN_IF" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
ensure_input_rule "$IP6" 4 -i "$WAN_IF" -j DROP
