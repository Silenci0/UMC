.PHONY: all clean release revision
.NOTPARALLEL: release clean

COMPILER_DIR ?= $(HOME)/serverfiles/tf/addons/sourcemod/scripting
COMPILER_NAME ?= spcomp64
COMPILER = $(COMPILER_DIR)/$(COMPILER_NAME)

INCLUDES_DIR = src/include
COMPILER_FLAGS = -i "$(INCLUDES_DIR)" -i "$(COMPILER_DIR)/include" -D "build/"

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
