#
# Makefile
# Peter Jones, 2019-01-23 15:35
#
default: all

EFI_ARCH ?= $(shell $(CC) -dumpmachine | cut -f1 -d- | \
	    sed \
		-e s,aarch64,aa64, \
		-e 's,arm.*,arm,' \
		-e s,i[3456789]86,ia32, \
		-e s,x86_64,x64, \
		)

ifeq ($(MAKELEVEL),0)
ifneq (, $(shell which git))
TOPDIR != if [ "$$(git rev-parse --is-inside-work-tree)" = true ]; then echo $$(realpath ./$$(git rev-parse --show-cdup)) ; else echo $(PWD) ; fi
else
TOPDIR != echo $(PWD)
endif
BUILDDIR ?= $(TOPDIR)/build-$(EFI_ARCH)
endif

include $(TOPDIR)/include/version.mk
export VERSION DASHRELEASE EFI_ARCH

all : | mkbuilddir
% : |
	@if ! [ -d $(BUILDDIR)/ ] ; then $(MAKE) BUILDDIR=$(BUILDDIR) TOPDIR=$(TOPDIR) mkbuilddir ; fi
	$(MAKE) TOPDIR=$(TOPDIR) BUILDDIR=$(BUILDDIR) -C $(BUILDDIR) -f Makefile $@

mkbuilddir :
	@mkdir -p $(BUILDDIR)
	@ln -f $(TOPDIR)/include/build.mk $(BUILDDIR)/Makefile

update :
	git submodule update --init --recursive
	cd $(TOPDIR)/edk2/ ; \
		git submodule set-branch --branch shim-16 CryptoPkg/Library/OpensslLib/openssl
	cd $(TOPDIR) ; \
		git submodule set-branch --branch shim-16 edk2 ; \
		git submodule sync --recursive
	cd $(TOPDIR)/edk2/CryptoPkg/Library/OpensslLib/openssl ; \
		git fetch origin ; \
		git checkout shim-16 ; \
		git rebase origin/shim-16
	cd $(TOPDIR)/edk2/CryptoPkg/Library/OpensslLib ; \
		if ! git diff-index --quiet HEAD -- openssl ; then \
			git commit -m "Update openssl" openssl ; \
		fi
	cd $(TOPDIR)/edk2 ; : \
		git fetch origin ; \
		git checkout shim-16 ; \
		git rebase origin/shim-16
	cd $(TOPDIR) ; \
		if ! git diff-index --quiet HEAD -- edk2 ; then \
			git commit -m "Update edk2" edk2 ; \
		fi
	cd $(TOPDIR)/Cryptlib ; \
		./update.sh

.PHONY: mkbuilddir update
.NOTPARALLEL:
# vim:ft=make
#
