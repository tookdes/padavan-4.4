THISDIR = $(shell pwd)
SRC_DIR = $(THISDIR)/src

COPTS := -DNOGRAPH

all: config_test
	$(MAKE) -j$(HOST_NCPU) -C $(SRC_DIR) COPTS="$(COPTS)"

config_test:
	( if [ -f $(SRC_DIR)/config_done ]; then \
		echo "the same configuration"; \
	else \
		make configure \&\& touch $(SRC_DIR)/config_done; \
	fi )

configure:
	( cd $(SRC_DIR) ; \
	CPPFLAGS="-I$(STAGEDIR)/include" \
	LDFLAGS="-L$(STAGEDIR)/lib" \
	./configure \
		--prefix=/usr \
		--host=$(HOST_TARGET) \
		--build=$(HOST_BUILD) \
		--disable-shared \
		--enable-static ; \
	)

clean:
	( if [ -f $(SRC_DIR)/Makefile ] ; then \
		$(MAKE) -C $(SRC_DIR) distclean ; \
	fi )
	rm -f $(SRC_DIR)/config_done

romfs:
	$(ROMFSINST) -p +x $(SRC_DIR)/bandwidthd /usr/bin/bandwidthd
	$(ROMFSINST) $(SRC_DIR)/bandwidthd.conf /etc_ro/bandwidthd.conf
	$(ROMFSINST) -d $(SRC_DIR)/htdocs /www/bandwidthd
