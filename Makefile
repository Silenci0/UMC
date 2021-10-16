.PHONY: all clean release install upgrade
.NOTPARALLEL: release clean install upgrade

COMPILER_DIR ?= $(HOME)/serverfiles/tf/addons/sourcemod/scripting
COMPILER_NAME ?= spcomp64
COMPILER = $(COMPILER_DIR)/$(COMPILER_NAME)

INCLUDES_DIR = $(abspath src/include)
COMPILER_FLAGS = -i"$(COMPILER_DIR)/include" -i"$(INCLUDES_DIR)" -D "build/" -O2 -v2

INSTALL_DIR ?= $(HOME)/serverfiles/tf/

sources = $(wildcard src/*.sp)
objects = $(sources:src/%.sp=build/%.smx)
revision = $(shell git rev-parse --short HEAD)

all: $(objects)

build/%.smx : src/%.sp
	$(COMPILER) $(COMPILER_FLAGS) "../$?"

clean:
	rm -rf build/release
	find build/ -type f -not -name '.keep' -not -name '$(revision).tar.bz2' -delete

release: clean all
	mkdir -p build/release/addons/sourcemod/plugins
	mkdir -p build/release/cfg
	cp -r config/sourcemod build/release/cfg/
	cp -r config/translations build/release/addons/sourcemod/
	cp build/*.smx build/release/addons/sourcemod/plugins
	cp -r src build/release/addons/sourcemod/scripting/
	cp config/umc_mapcycle.txt build/release
	cp config/vote_warnings.txt build/release
	tar -cjvf "build/$(revision).tar.bz2" -C build/release .
	make clean

# Note that installing will reset all of the existing configs. You probably do
# not want that if you are upgrading.
install: release
	tar -xjvf "build/$(revision).tar.bz2" -C "$(INSTALL_DIR)"

upgrade: clean all
	mv -v build/*.smx "$(INSTALL_DIR)/addons/sourcemod/plugins"
