#!/bin/sh
# KumaSocks transparent proxy to SOCKS5
# For Padavan firmware

export PATH=/usr/sbin:/usr/bin:/sbin:/bin

KSOCKS_CONF="/tmp/kumasocks.toml"
KSOCKS_PID="/var/run/kumasocks.pid"
KSOCKS_LOG="/tmp/kumasocks.log"

is_valid_port() {
	case "$1" in
		""|*[!0-9]*) return 1 ;;
	esac
	[ "$1" -ge 1 ] 2>/dev/null && [ "$1" -le 65535 ] 2>/dev/null
}

is_valid_socks5_addr() {
	[ -n "$1" ] || return 1
	printf '%s' "$1" | grep -Eq '^[A-Za-z0-9._:-]+$' || return 1
	printf '%s' "$1" | grep -Eq '^[A-Za-z0-9._-]+:[0-9]{1,5}$' || return 1
	port=${1##*:}
	is_valid_port "$port"
}

add_prerouting_rule() {
	iptables -t nat -A PREROUTING "$@" -p tcp -j KUMASOCKS
}

cleanup_rules() {
	while iptables -t nat -D PREROUTING -p tcp -j KUMASOCKS 2>/dev/null; do :; done
	while iptables -t nat -D PREROUTING -s 0.0.0.0/0 -p tcp -j KUMASOCKS 2>/dev/null; do :; done
	iptables-save -t nat 2>/dev/null | sed -n 's/^-A PREROUTING \(.*\) -p tcp -j KUMASOCKS$/\1/p' | while read -r match; do
		[ -n "$match" ] && iptables -t nat -D PREROUTING $match -p tcp -j KUMASOCKS 2>/dev/null
	done
	iptables-save 2>/dev/null | sed -n 's/^-A INPUT \(.*\) -j KUMASOCKS_INPUT$/\1/p' | while read -r match; do
		[ -n "$match" ] && iptables -D INPUT $match -j KUMASOCKS_INPUT 2>/dev/null
	done
	iptables -F KUMASOCKS_INPUT 2>/dev/null
	iptables -X KUMASOCKS_INPUT 2>/dev/null
}

start_kumasocks() {
	enable=$(nvram get kumasocks_enable)
	[ "$enable" != "1" ] && return 0

	listen_port=$(nvram get kumasocks_listen_port)
	[ -z "$listen_port" ] && listen_port="1234"
	if ! is_valid_port "$listen_port"; then
		syslog_logger "KumaSocks: invalid listen port"
		return 1
	fi

	socks5_addr=$(nvram get kumasocks_socks5_addr)
	[ -z "$socks5_addr" ] && return 0
	if ! is_valid_socks5_addr "$socks5_addr"; then
		syslog_logger "KumaSocks: invalid SOCKS5 address"
		return 1
	fi

	cat > "$KSOCKS_CONF" <<EOF
listen-addr = "0.0.0.0:$listen_port"
proxy-addr  = "socks5://$socks5_addr"
EOF

	killall -q kumasocks 2>/dev/null
	sleep 1

	/usr/bin/kumasocks -c "$KSOCKS_CONF" > "$KSOCKS_LOG" 2>&1 &
	echo $! > "$KSOCKS_PID"

	iptables -t nat -N KUMASOCKS 2>/dev/null
	iptables -t nat -F KUMASOCKS 2>/dev/null
	cleanup_rules
	iptables -N KUMASOCKS_INPUT 2>/dev/null
	iptables -F KUMASOCKS_INPUT 2>/dev/null
	iptables -A KUMASOCKS_INPUT -j DROP
	iptables -I INPUT ! -i br0 -p tcp --dport "$listen_port" -j KUMASOCKS_INPUT

	# bypass private/reserved networks
	iptables -t nat -A KUMASOCKS -d 0.0.0.0/8     -j RETURN
	iptables -t nat -A KUMASOCKS -d 10.0.0.0/8    -j RETURN
	iptables -t nat -A KUMASOCKS -d 127.0.0.0/8   -j RETURN
	iptables -t nat -A KUMASOCKS -d 169.254.0.0/16 -j RETURN
	iptables -t nat -A KUMASOCKS -d 172.16.0.0/12  -j RETURN
	iptables -t nat -A KUMASOCKS -d 192.168.0.0/16 -j RETURN
	iptables -t nat -A KUMASOCKS -d 224.0.0.0/4    -j RETURN
	iptables -t nat -A KUMASOCKS -d 240.0.0.0/4    -j RETURN

	iptables -t nat -A KUMASOCKS -p tcp -j REDIRECT --to-ports "$listen_port"

	lan_only=$(nvram get kumasocks_lan_only)
	if [ "$lan_only" = "1" ]; then
		lan_net=$(nvram get lan_ipaddr | awk -F. '{print $1"."$2"."$3".0/24"}')
		add_prerouting_rule -s "$lan_net"
	else
		add_prerouting_rule
	fi

	syslog_logger "KumaSocks started (listen $listen_port -> socks5 $socks5_addr)"
}

stop_kumasocks() {
	if [ -f "$KSOCKS_PID" ]; then
		kill $(cat "$KSOCKS_PID") 2>/dev/null
		rm -f "$KSOCKS_PID"
	fi
	killall -q kumasocks 2>/dev/null

	cleanup_rules
	iptables -t nat -F KUMASOCKS 2>/dev/null
	iptables -t nat -X KUMASOCKS 2>/dev/null

	syslog_logger "KumaSocks stopped"
}

case "$1" in
start)
	start_kumasocks
	;;
stop)
	stop_kumasocks
	;;
restart)
	stop_kumasocks
	sleep 1
	start_kumasocks
	;;
*)
	echo "Usage: $0 {start|stop|restart}"
	exit 1
	;;
esac

exit 0
