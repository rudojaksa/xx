PACKAGE	:= xx
VERSION	:= 0.4
AUTHOR	:= R.Jaksa 2023,2024 GPLv3
SUBVERSION := 

all:
	@echo -e "\nto install choose:\n"
	@echo "  make install"
	@echo "  make install4group"
	@echo "  make install4host"
	@echo

# install to the private bin
install: xx
	cat xx | \
	sed 's:\(from the text console\):\1 (version xx-$(VERSION)$(SUBVERSION)):' > ~/bin/xx

# install the group-based access version
install4group: xx
	sed -z 's:\n\n# 4.:\nchgrp xorg $$XAUTHORITY; chmod 640 $$XAUTHORITY\n\n# 4.:' xx | \
	sed 's:\(from the text console\):\1 (version xx-$(VERSION)$(SUBVERSION)):' > ~/bin/xx

# install the host-based access version
install4host: xx
	sed -z 's:\n\n# 4.:\nchmod 644 $$XAUTHORITY\n\n# 4.:' xx | \
	sed 's:\(from the text console\):\1 (version xx-$(VERSION)$(SUBVERSION)):' > ~/bin/xx

clean:

-include ~/.github/Makefile.git
