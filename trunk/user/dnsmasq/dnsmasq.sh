#!/bin/sh

filter_aaaa=$(nvram get dhcp_filter_aaa)
min_ttl=$(nvram get dhcp_min_ttl)
sed -i '/filter-aaaa/d' /etc/storage/dnsmasq/dnsmasq.conf
if [ "$filter_aaaa" = "1" ]; then
	cat >>/etc/storage/dnsmasq/dnsmasq.conf <<EOF
filter-aaaa
EOF
fi


