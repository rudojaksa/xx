PACKAGE	:= xx
VERSION	:= 0.5
AUTHOR	:= R.Jaksa 2023,2024 GPLv3
SUBVERSION :=a
PKGNAME := xx-$(VERSION)$(SUBVERSION)

all:
	@echo -e "\nto install choose:\n"
	@echo "  make install"
	@echo "  make install4group"
	@echo "  make install4host"
	@echo

# install to the private bin
install: xx.tmp
	sed -i -z 's:\n#[GH]#[^\n]*::g' $<
	mv $< ~/bin/xx

# install the group-based-access version
install4group: xx.tmp
	sed -i -z 's:\n#H#[^\n]*::g' $<
	sed -i 's:^#G# *::g' $<
	mv $< ~/bin/xx

# install the host-based-access version
install4host: xx.tmp
	sed -i -z 's:\n#G#[^\n]*::g' $<
	sed -i 's:^#H# *::g' $<
	mv $< ~/bin/xx

# add version name to the installed script
xx.tmp: xx Makefile
	sed 's:\(from the text console\):\1 (version $(PKGNAME)):' $< > $@
	chmod 755 $@

clean:
	rm -f xx.tmp

-include ~/.github/Makefile.git
