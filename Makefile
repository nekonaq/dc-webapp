SHELL = /bin/bash

run		= $(nil)
SERVICE		= $(notdir $(PWD))

DESTDIR		=
INSTALL_OWNER	= root
INSTALL_GROUP	= root

SERVICE_PREFIX	= docker-compose@
SYSCONFDIR	= $(DESTDIR)/etc/default
UNITDIR_LIB	= $(DESTDIR)/lib/systemd/system
UNITDIR_ETC	= $(DESTDIR)/etc/systemd/system

OVERRIDE	= override.conf
ifeq (,$(wildcard $(OVERRIDE)))
OVERRIDE_CONF	= $(nil)
else
# カレントディレクトリに override.conf があれば仕込む
OVERRIDE_CONF	= $(UNITDIR_ETC)/$(SERVICE_PREFIX)$(SERVICE).service.d/$(OVERRIDE)
endif

all:; $(error No target specified)

#//
install remove name status start stop enable disable:
	@$(MAKE) --no-print-directory $(SERVICE_PREFIX)$(SERVICE).service/$@

$(addsuffix .service/install,$(SERVICE_PREFIX)$(SERVICE)): %/install: $(SYSCONFDIR)/% $(OVERRIDE_CONF) FORCE
	@( set -x; $(run) systemctl daemon-reload )

$(addsuffix .service/remove,$(SERVICE_PREFIX)$(SERVICE)): %/remove: FORCE
	@( set -x; \
	   $(run) systemctl stop $* ||:; \
	   $(run) systemctl disable $* ||: ; \
	   $(run) rm -rf $(basename $(SYSCONFDIR)/$*) $(dir $(OVERRIDE_CONF)); \
	   $(run) systemctl daemon-reload; \
	)

$(addsuffix .service/name,$(SERVICE_PREFIX)$(SERVICE)): %/name: FORCE
	@echo $*

$(addsuffix .service/status,$(SERVICE_PREFIX)$(SERVICE)): %/status: FORCE
	@( set -x; $(run) systemctl status $* ||:; )

$(addsuffix .service/start,$(SERVICE_PREFIX)$(SERVICE)): %/start: FORCE
	@( set -x; $(run) systemctl start $* ||:; )

$(addsuffix .service/stop,$(SERVICE_PREFIX)$(SERVICE)): %/stop: FORCE
	@( set -x; $(run) systemctl stop $* ||:; )

$(addsuffix .service/enable,$(SERVICE_PREFIX)$(SERVICE)): %/enable: FORCE
	@( set -x; $(run) systemctl enable $* ||:; )

$(addsuffix .service/disable,$(SERVICE_PREFIX)$(SERVICE)): %/disable: FORCE
	@( set -x; $(run) systemctl disable $* ||:; )

#//
$(SYSCONFDIR)/%: FORCE
	@if [ ! -e $(basename $@) ]; then \
	  ( set -x; $(run) ln -sf $(PWD) $(basename $@) ); \
	fi

ifdef OVERRIDE_CONF
$(OVERRIDE_CONF): $(OVERRIDE)
	@( set -x; \
	   $(run) install -o $(INSTALL_OWNER) -g $(INSTALL_GROUP) -m 744 -d $(@D); \
	   $(run) install -o $(INSTALL_OWNER) -g $(INSTALL_GROUP) -m 644 $< $@; \
	)

endif

#//
FORCE:
