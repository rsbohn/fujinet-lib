# Adapted from the generic cc65 makefile.
# Notible exceptions:
# - recursive dirs for src
# - final files go into build/ directory instead of polluting root folder (e.g. lbl, com file etc)

###############################################################################
### In order to override defaults - values can be assigned to the variables ###
###############################################################################

# Space or comma separated list of cc65 supported target platforms to build for.
TARGETS := atari apple2 commodore

# Name of the final, single-file library.
PROGRAM := fujinet.lib

# Path(s) to additional libraries required for linking the program
# Use only if you don't want to place copies of the libraries in SRCDIR
# Default: none
LIBS    :=

# Custom linker configuration file
# Use only if you don't want to place it in SRCDIR
# Default: none
CONFIG  :=

# Additional C compiler flags and options.
# Default: none
CFLAGS  =

# Additional assembler flags and options.
# Default: none
ASFLAGS =

# Additional linker flags and options.
# Default: none
LDFLAGS =

# Path to the directory containing C and ASM sources.
# Default: src
SRCDIR :=

# Path to the directory where object files are to be stored (inside respective target subdirectories).
# Default: obj
OBJDIR :=

# Command used to run the emulator.
# Default: depending on target platform. For default (c64) target: x64 -kernal kernal -VICIIdsize -autoload
EMUCMD :=

# Build dir for putting final built program rather than cluttering root
BUILD_DIR = build

# Options state file name. You should not need to change this, but for those
# rare cases when you feel you really need to name it differently - here you are
STATEFILE := Makefile.options

# Object Dir for writing compiled files to
OBJDIR := obj

###################################################################################
####  DO NOT EDIT BELOW THIS LINE, UNLESS YOU REALLY KNOW WHAT YOU ARE DOING!  ####
###################################################################################

CC65_TARGET_apple2     := apple2
CC65_TARGET_atari      := atari
CC65_TARGET_commodore  := c64

###################################################################################
### Mapping abstract options to the actual compiler, assembler and linker flags ###
### Predefined compiler, assembler and linker flags, used with abstract options ###
### valid for 2.14.x. Consult the documentation of your cc65 version before use ###
###################################################################################

# Compiler flags used to tell the compiler to optimise for SPEED
define _optspeed_
  CFLAGS += -Oris
endef

# Compiler flags used to tell the compiler to optimise for SIZE
define _optsize_
  CFLAGS += -Or
endef

# Compiler and assembler flags for generating listings
define _listing_
  CFLAGS += --listing $(BUILD_DIR)/$$(@:.o=.lst)
  ASFLAGS += --listing $(BUILD_DIR)/$$(@:.o=.lst)
  REMOVES += $(addsuffix .lst,$(basename $(OBJECTS)))
endef

# Linker flags for generating map file
define _mapfile_
  LDFLAGS += --mapfile $(BUILD_DIR)/$$@.map
  REMOVES += $(BUILD_DIR)/$(PROGRAM).map
endef

# Linker flags for generating VICE label file
define _labelfile_
  LDFLAGS += -Ln $(BUILD_DIR)/$$@.lbl
  REMOVES += $(BUILD_DIR)/$(PROGRAM).lbl
endef

# Linker flags for generating a debug file
define _debugfile_
  LDFLAGS += -Wl --dbgfile,$(BUILD_DIR)/$$@.dbg
  REMOVES += $(BUILD_DIR)/$(PROGRAM).dbg
endef

###############################################################################
###  Defaults to be used if nothing defined in the editable sections above  ###
###############################################################################

# Presume the C64 target like the cl65 compile & link utility does.
# Set TARGETS to override.
ifeq ($(TARGETS),)
  TARGETS := c64
endif

# Presume we're in a project directory so name the program like the current
# directory. Set PROGRAM to override.
ifeq ($(PROGRAM),)
  PROGRAM := $(notdir $(CURDIR))
endif

# Presume the C and asm source files to be located in the subdirectory 'src'.
# Set SRCDIR to override.
ifeq ($(SRCDIR),)
  SRCDIR := src
endif

TARGETOBJDIR := $(OBJDIR)/$(TARGETS)

# On Windows it is mandatory to have CC65_HOME set. So do not unnecessarily
# rely on cl65 being added to the PATH in this scenario.
ifdef CC65_HOME
  CC := $(CC65_HOME)/bin/cl65
else
  CC := cl65
endif

ifeq ($(shell echo),)
  MKDIR = mkdir -p $1
  RMDIR = rmdir $1
  RMFILES = $(RM) $1
else
  MKDIR = mkdir $(subst /,\,$1)
  RMDIR = rmdir $(subst /,\,$1)
  RMFILES = $(if $1,del /f $(subst /,\,$1))
endif
COMMA := ,
SPACE := $(N/A) $(N/A)
define NEWLINE


endef
# Note: Do not remove any of the two empty lines above !

rwildcard=$(wildcard $(1)$(2))$(foreach d,$(wildcard $1*), $(call rwildcard,$d/,$2))

TARGETLIST := $(subst $(COMMA),$(SPACE),$(TARGETS))

ifeq ($(words $(TARGETLIST)),1)

# Strip potential variant suffix from the actual cc65 target.
CC65TARGET := $(firstword $(subst .,$(SPACE),$(TARGETLIST)))

# Set PROGRAM to something like 'myprog.c64'.
override PROGRAM := $(PROGRAM).$(TARGETLIST)

# Recursive files
SOURCES += $(call rwildcard,$(TARGETLIST)/$(SRCDIR)/,*.s)
SOURCES += $(call rwildcard,$(TARGETLIST)/$(SRCDIR)/,*.c)
SOURCES += $(call rwildcard,common/$(SRCDIR)/,*.s)
SOURCES += $(call rwildcard,common/$(SRCDIR)/,*.c)

# remove trailing and leading spaces.
SOURCES := $(strip $(SOURCES))

# Set OBJECTS to something like 'obj/c64/foo.o obj/c64/bar.o'.
# convert from src/your/long/path/foo.[c|s] to obj/your/long/path/foo.o
OBJ1 := $(SOURCES:.c=.o)
OBJECTS := $(OBJ1:.s=.o)
# change from atari/src/ -> obj/atari/
OBJECTS := $(OBJECTS:$(TARGETLIST)/$(SRCDIR)/%=$(OBJDIR)/$(TARGETLIST)/%)
OBJECTS := $(OBJECTS:common/$(SRCDIR)/%=$(OBJDIR)/common/%)

# Set DEPENDS to something like 'obj/c64/foo.d obj/c64/bar.d'.
DEPENDS := $(OBJECTS:.o=.d)

# Add to LIBS something like atari/src/bar.lib'.
LIBS += $(wildcard $(TARGETLIST)/$(SRCDIR)/*.lib)

ASFLAGS += \
	--asm-include-dir common/inc \
	--asm-include-dir $(TARGETLIST)/$(SRCDIR)/fn_network/inc \
	--asm-include-dir $(TARGETLIST)/$(SRCDIR)/fn_io/inc \
	--asm-include-dir $(TARGETLIST)/$(SRCDIR)/fn_fuji/inc \
	--asm-include-dir .

CFLAGS += \
	--include-dir common/inc \
	--include-dir $(TARGETLIST)/$(SRCDIR)/fn_network/inc \
	--include-dir $(TARGETLIST)/$(SRCDIR)/fn_io/inc \
	--include-dir $(TARGETLIST)/$(SRCDIR)/fn_fuji/inc \
	--include-dir .

# Add -DBUILD_(TARGET) to all args for the current name.
UPPER_TARGETLIST := $(shell echo $(TARGETLIST) | tr a-z A-Z)
CFLAGS += -DBUILD_$(UPPER_TARGETLIST)
ASFLAGS += -DBUILD_$(UPPER_TARGETLIST)
LDFLAGS += -DBUILD_$(UPPER_TARGETLIST)


CHANGELOG = Changelog.md

# single line with version number in semantic form (e.g. 2.1.3)
VERSION_FILE = version.txt
VERSION_STRING := $(file < $(VERSION_FILE))

# include files that are included in the ZIP dist/release target
FN_NW_HEADER = fujinet-network.h
FN_NW_INC = fujinet-network.inc
FN_IO_HEADER = fujinet-io.h
FN_IO_INC = fujinet-io.inc

.SUFFIXES:
.PHONY: all clean dist fujinet-network.lib.$(TARGETLIST)

all: fujinet-network.lib.$(TARGETLIST)

-include $(DEPENDS)
-include $(STATEFILE)

# If OPTIONS are given on the command line then save them to STATEFILE
# if (and only if) they have actually changed. But if OPTIONS are not
# given on the command line then load them from STATEFILE. Have object
# files depend on STATEFILE only if it actually exists.
ifeq ($(origin OPTIONS),command line)
  ifneq ($(OPTIONS),$(_OPTIONS_))
    ifeq ($(OPTIONS),)
      $(info Removing OPTIONS)
      $(shell $(RM) $(STATEFILE))
      $(eval $(STATEFILE):)
    else
      $(info Saving OPTIONS=$(OPTIONS))
      $(shell echo _OPTIONS_=$(OPTIONS) > $(STATEFILE))
    endif
    $(eval $(OBJECTS): $(STATEFILE))
  endif
else
  ifeq ($(origin _OPTIONS_),file)
    $(info Using saved OPTIONS=$(_OPTIONS_))
    OPTIONS = $(_OPTIONS_)
    $(eval $(OBJECTS): $(STATEFILE))
  endif
endif

# Transform the abstract OPTIONS to the actual cc65 options.
$(foreach o,$(subst $(COMMA),$(SPACE),$(OPTIONS)),$(eval $(_$o_)))

$(OBJDIR):
	$(call MKDIR,$@)

$(TARGETOBJDIR):
	$(call MKDIR,$@)

$(BUILD_DIR):
	$(call MKDIR,$@)

SRC_INC_DIRS := \
	$(sort $(dir $(wildcard $(TARGETLIST)/$(SRCDIR)/*))) \
	$(sort $(dir $(wildcard common/$(SRCDIR)/*)))

# $(info $$SOURCES = ${SOURCES})
# $(info $$OBJECTS = ${OBJECTS})
# $(info $$SRC_INC_DIRS = ${SRC_INC_DIRS})
# $(info $$ASFLAGS = ${ASFLAGS})
# $(info $$TARGETOBJDIR = ${TARGETOBJDIR})
# $(info $$TARGETLIST = ${TARGETLIST})

vpath %.c $(SRC_INC_DIRS)

obj/common/%.o: %.c | $(TARGETOBJDIR)
	@$(call MKDIR,$(dir $@))
	$(CC) -t $(CC65_TARGET_$(TARGETLIST)) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

$(TARGETOBJDIR)/%.o: %.c | $(TARGETOBJDIR)
	@$(call MKDIR,$(dir $@))
	$(CC) -t $(CC65_TARGET_$(TARGETLIST)) -c --create-dep $(@:.o=.d) $(CFLAGS) -o $@ $<

vpath %.s $(SRC_INC_DIRS)

obj/common/%.o: %.s | $(TARGETOBJDIR)
	@$(call MKDIR,$(dir $@))
	$(CC) -t $(CC65_TARGET_$(TARGETLIST)) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

$(TARGETOBJDIR)/%.o: %.s | $(TARGETOBJDIR)
	@$(call MKDIR,$(dir $@))
	$(CC) -t $(CC65_TARGET_$(TARGETLIST)) -c --create-dep $(@:.o=.d) $(ASFLAGS) -o $@ $<

$(BUILD_DIR)/$(PROGRAM): $(OBJECTS) | $(BUILD_DIR)
	ar65 a $@ $(OBJECTS)

$(PROGRAM): $(BUILD_DIR)/$(PROGRAM) | $(BUILD_DIR)

clean:
	$(call RMFILES,$(OBJECTS))
	$(call RMFILES,$(DEPENDS))
	$(call RMFILES,$(REMOVES))
	$(call RMFILES,$(BUILD_DIR)/$(PROGRAM))

dist: $(PROGRAM)
	$(call MKDIR,dist/)
	$(call RMFILES,dist/fujinet-$(TARGETLIST)-*.lib)
	cp build/$(PROGRAM) dist/fujinet-$(TARGETLIST)-$(VERSION_STRING).lib
	cp $(FN_NW_HEADER) dist/
	cp $(FN_NW_INC) dist/
	cp $(FN_IO_HEADER) dist/
	cp $(FN_IO_INC) dist/
	cp $(CHANGELOG) dist/
	cd dist && zip fujinet-lib-$(TARGETLIST)-$(VERSION_STRING).zip $(CHANGELOG) fujinet-$(TARGETLIST)-$(VERSION_STRING).lib *.h *.inc
	$(call RMFILES,dist/fujinet-$(TARGETLIST)-*.lib)
	$(call RMFILES,dist/$(CHANGELOG))
	$(call RMFILES,dist/*.h)
	$(call RMFILES,dist/*.inc)

else # $(words $(TARGETLIST)),1

all:
	$(foreach t,$(TARGETLIST),$(MAKE) TARGETS=$t clean all dist$(NEWLINE))

endif # $(words $(TARGETLIST)),1


###################################################################
###  Place your additional targets in the additional Makefiles  ###
### in the same directory - their names have to end with ".mk"! ###
###################################################################
-include *.mk