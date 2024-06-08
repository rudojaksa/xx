PACKAGE	:= xx
VERSION	:= 0.7
AUTHOR	:= R.Jaksa 2023,2024 GPLv3
SUBVERSION := a
PKGNAME	:= xx-$(VERSION)$(SUBVERSION)

all:
	@echo -e "\nto install choose single-user, group-based or host-based access:\n"
	@echo "  make install"
	@echo "  make install4group"
	@echo "  make install4host"
	@echo

# install to the private bin
install: xx.tmp installpulse
	sed -i -z 's:\n#[GH]#[^\n]*::g' $<
	mv $< ~/bin/xx

# install the group-based-access version
install4group: xx.tmp installpulse
	sed -i -z 's:\n#H#[^\n]*::g' $<
	sed -i 's:^#G# *::g' $<
	mv $< ~/bin/xx

# install the host-based-access version
install4host: xx.tmp installpulse
	sed -i -z 's:\n#G#[^\n]*::g' $<
	sed -i 's:^#H# *::g' $<
	mv $< ~/bin/xx

# add version name to the installed script
# remove section 3. and pulse-cleanup if /etc/pulse doesn't exist
xx.tmp: xx Makefile
	sed 's:\(from the text console\):\1 (version $(PKGNAME)):' $< > $@
	if test ! -d /etc/pulse; then \
	  perl -gpi -e 's/\n# 3. .*?\n\n/\n/s' $@; \
	  perl -gpi -e 's/\npkill -9 pulseaudio.*?\n/\n/s' $@; \
	  perl -gpi -e 's/\nrm -rvf \/tmp\/pulse.*?\n/\n/s' $@; fi
	chmod 755 $@

# interactive overwrite of pulse configs if needed
installpulse:
	@pulse/install-clientconf
	@pulse/install-defaultpa
	@echo

clean:
	rm -f xx.tmp

-include ~/.github/Makefile.git
