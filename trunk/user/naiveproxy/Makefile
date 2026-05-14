THISDIR = $(shell pwd)

# NaiveProxy prebuilt for OpenWrt mipsel_24kc (MT7621/MT7620)
# See: https://github.com/klzgrad/naiveproxy/releases
NAIVE_VERSION := 148.0.7778.96-5
NAIVE_URL := https://github.com/klzgrad/naiveproxy/releases/download/v$(NAIVE_VERSION)/naiveproxy-v$(NAIVE_VERSION)-openwrt-mipsel_24kc.tar.xz

all: download

download:
	( if [ ! -f $(THISDIR)/naiveproxy.tar.xz ]; then \
		curl -L --create-dirs $(NAIVE_URL) -o $(THISDIR)/naiveproxy.tar.xz ; \
	fi )
	( if [ ! -d $(THISDIR)/naiveproxy ]; then \
		mkdir -p $(THISDIR)/naiveproxy && \
		tar xJf $(THISDIR)/naiveproxy.tar.xz -C $(THISDIR)/naiveproxy --strip-components=1 ; \
	fi )

clean:
	rm -rf $(THISDIR)/naiveproxy
	rm -f $(THISDIR)/naiveproxy.tar.xz

romfs:
	$(ROMFSINST) -p +x $(THISDIR)/naiveproxy/naive /usr/bin/naive
	$(ROMFSINST) $(THISDIR)/naiveproxy/ca-certificates.crt /etc_ro/naive-ca-certificates.crt
