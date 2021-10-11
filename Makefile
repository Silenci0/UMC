COMPILER_DIR ?= $(HOME)/serverfiles/tf/addons/sourcemod/scripting
COMPILER_NAME ?= spcomp64
COMPILER = $(COMPILER_DIR)/$(COMPILER_NAME)

INCLUDES_DIR = src/include
COMPILER_FLAGS = -i "$(INCLUDES_DIR)" -i "$(COMPILER_DIR)/include" -D "build/"

sources = $(wildcard src/*.sp)
objects = $(sources:src/%.sp=build/%.smx)

all: $(objects)

build/%.smx : src/%.sp
	$(COMPILER) $(COMPILER_FLAGS) "../$?"

clean:
	find build/ type -f -not -name '.keep' -delete
