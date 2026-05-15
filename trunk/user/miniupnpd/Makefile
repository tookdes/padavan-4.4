SRC_NAME=miniupnpd-2.3.10
SRC_URL=https://miniupnp.tuxfamily.org/files/$(SRC_NAME).tar.gz

# reference to iptables package
IPT_VERSION:=iptables-1.8.7

# disable support IPv6 yet, because no profit w/o IGDv2
# e.g. Windows not supported IGDv2 and UPnP not worked
ENABLE_IPV6:=0
IPV6_CONFIG_OPT=$(if $(filter 1 y yes,$(ENABLE_IPV6)),--ipv6,)

IPTABLESPATH=$(ROOTDIR)/user/iptables/$(IPT_VERSION)

all:
	$(MAKE) download_test extract_test config_test
	$(MAKE) -f Makefile.linux -C $(SRC_NAME) IPTABLESPATH=$(IPTABLESPATH)

download_test:
	( if [ ! -f $(SRC_NAME).tar.gz ]; then \
		wget -t5 --timeout=20 --no-check-certificate -O $(SRC_NAME).tar.gz $(SRC_URL); \
	fi )

extract_test:
	( if [ ! -d $(SRC_NAME) ]; then \
		tar zxf $(SRC_NAME).tar.gz; \
		sed -i '/#define ENABLE_EVENTS/d' $(SRC_NAME)/configure; \
		sed -i 's/ upnpevents\.o//' $(SRC_NAME)/objects.mk; \
	fi )

config_test:
	( cd $(SRC_NAME) ; \
		./configure \
			--disable-tests \
			--firewall=iptables \
			--iptablespath=$(IPTABLESPATH) \
			$(IPV6_CONFIG_OPT) ; \
	)

clean:
	if [ -f $(SRC_NAME)/Makefile.linux ] ; then \
		$(MAKE) -f Makefile.linux -C $(SRC_NAME) clean ; \
	fi
	rm -f miniupnpd

romfs:
	cp $(SRC_NAME)/miniupnpd .
	$(ROMFSINST) /usr/bin/miniupnpd
