# Changelog
# Changed the variables to include the header file directory
# Added global var for the XTENSA tool root
#
# This make file still needs some work.
#
#
# Output directors to store intermediate compiled files
# relative to the project directory
BUILD_BASE	= build
FW_BASE		= firmware
FLAVOR = release
#FLAVOR = debug

# Base directory for the compiler
XTENSA_TOOLS_ROOT ?= c:/Espressif/xtensa-lx106-elf/bin

# base directory of the ESP8266 SDK package, absolute
SDK_BASE	?= c:/Espressif/ESP8266_SDK

#Esptool.py path and port
PYTHON		?= C:\Python27\python.exe
ESPTOOL		?= c:\Espressif\utils\esptool.py
ESPPORT		?= COM2

# name for the target project
TARGET		= app

# which modules (subdirectories) of the project to include in compiling
MODULES		= driver user lwip json	ssl upgrade

EXTRA_INCDIR    = include $(SDK_BASE)/../include

# libraries used in this project, mainly provided by the SDK
LIBS		= c gcc hal phy pp net80211 lwip wpa json main upgrade

# compiler flags using during compilation of source files
CFLAGS		= -Os -Wpointer-arith -Wundef -Werror -Wl,-EL -fno-inline-functions -nostdlib -mlongcalls -mtext-section-literals  -D__ets__ -DICACHE_FLASH

# linker flags used to generate the main object file
LDFLAGS		= -nostdlib -Wl,--no-check-sections -u call_user_start -Wl,-static


ifeq ($(FLAVOR),debug)
    CFLAGS += -g -O2
    LDFLAGS += -g -O2
endif

ifeq ($(FLAVOR),release)
    CFLAGS += -g -O0
    LDFLAGS += -g -O0
endif

# linker script used for the above linkier step
LD_SCRIPT	= eagle.app.v6.ld
LD_SCRIPT1 	= eagle.app.v6.app1.ld
LD_SCRIPT2 	= eagle.app.v6.app2.ld
# various paths from the SDK used in this project
SDK_LIBDIR	= lib
SDK_LDDIR	= ld
SDK_INCDIR	= include include/json

# we create two different files for uploading into the flash
# these are the names and options to generate them
FW_FILE_1	= 0x00000
FW_FILE_1_ARGS	= -bo $@ -bs .text -bs .data -bs .rodata -bc -ec
FW_FILE_2	= 0x40000
FW_FILE_2_ARGS	= -es .irom0.text $@ -ec

FW_USER1_1	= user1_0x01000
FW_USER1_1_ARGS	= -bo $@ -bs .text -bs .data -bs .rodata -bc -ec

FW_USER1_2	= user1_0x11000
FW_USER1_2_ARGS	= -es .irom0.text $@ -ec

FW_USER2_1	= user2_0x41000
FW_USER2_1_ARGS	= -bo $@ -bs .text -bs .data -bs .rodata -bc -ec

FW_USER2_2	= user2_0x51000
FW_USER2_2_ARGS	= -es .irom0.text $@ -ec


# select which tools to use as compiler, librarian and linker
CC		:= $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-gcc
AR		:= $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-ar
LD		:= $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-gcc

####
#### no user configurable options below here
####
FW_TOOL		?= $(XTENSA_TOOLS_ROOT)/esptool
MERGE_TOOL		?= $(SDK_BASE)/tools/gen_flashbin.py
SRC_DIR		:= $(MODULES)
BUILD_DIR	:= $(addprefix $(BUILD_BASE)/,$(MODULES))

SDK_LIBDIR	:= $(addprefix $(SDK_BASE)/,$(SDK_LIBDIR))
SDK_INCDIR	:= $(addprefix -I$(SDK_BASE)/,$(SDK_INCDIR))

SRC		:= $(foreach sdir,$(SRC_DIR),$(wildcard $(sdir)/*.c))
OBJ		:= $(patsubst %.c,$(BUILD_BASE)/%.o,$(SRC))
LIBS		:= $(addprefix -l,$(LIBS))
APP_AR		:= $(addprefix $(BUILD_BASE)/,$(TARGET)_app.a)
TARGET_OUT	:= $(addprefix $(BUILD_BASE)/,$(TARGET).out)

APP_AR		:= $(addprefix $(BUILD_BASE)/,$(TARGET)_app.a)
TARGET_OUT	:= $(addprefix $(BUILD_BASE)/,$(TARGET).out)

APP_AR1		:= $(addprefix $(BUILD_BASE)/,$(TARGET)_app1.a)
TARGET_OUT1	:= $(addprefix $(BUILD_BASE)/,$(TARGET)1.out)
APP_AR2		:= $(addprefix $(BUILD_BASE)/,$(TARGET)2_app.a)
TARGET_OUT2	:= $(addprefix $(BUILD_BASE)/,$(TARGET)2.out)

LD_SCRIPT	:= $(addprefix -T$(SDK_BASE)/$(SDK_LDDIR)/,$(LD_SCRIPT))

LD_SCRIPT_U1	:= $(addprefix -T$(SDK_BASE)/$(SDK_LDDIR)/,$(LD_SCRIPT1))
LD_SCRIPT_U2	:= $(addprefix -T$(SDK_BASE)/$(SDK_LDDIR)/,$(LD_SCRIPT2))

INCDIR	:= $(addprefix -I,$(SRC_DIR))
EXTRA_INCDIR	:= $(addprefix -I,$(EXTRA_INCDIR))
MODULE_INCDIR	:= $(addsuffix /include,$(INCDIR))

FW_FILE_1	:= $(addprefix $(FW_BASE)/,$(FW_FILE_1).bin)
FW_FILE_2	:= $(addprefix $(FW_BASE)/,$(FW_FILE_2).bin)

FW_FILE_U1_1	:= $(addprefix $(FW_BASE)/,$(FW_USER1_1).bin)
FW_FILE_U1_2	:= $(addprefix $(FW_BASE)/,$(FW_USER1_2).bin)
FW_FILE_U2_1	:= $(addprefix $(FW_BASE)/,$(FW_USER2_1).bin)
FW_FILE_U2_2	:= $(addprefix $(FW_BASE)/,$(FW_USER2_2).bin)
FW_FILE_U1	:= $(addprefix $(FW_BASE)/,user1.bin)
FW_FILE_U2	:= $(addprefix $(FW_BASE)/,user2.bin)
BOOTLOADER	:= $(addprefix $(SDK_BASE)/,bin/boot_v1.1.bin)
BLANKER	:= $(addprefix $(SDK_BASE)/,bin/blank.bin)
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))

V ?= $(VERBOSE)
ifeq ("$(V)","1")
Q :=
vecho := @true
else
Q := @
vecho := @echo
endif

vpath %.c $(SRC_DIR)

define compile-objects
$1/%.o: %.c
	$(vecho) "CC $$<"
	$(Q) $(CC) $(INCDIR) $(MODULE_INCDIR) $(EXTRA_INCDIR) $(SDK_INCDIR) $(CFLAGS)  -c $$< -o $$@
endef

.PHONY: all checkdirs clean

all: checkdirs $(TARGET_OUT) $(FW_FILE_1) $(FW_FILE_2)

$(FW_FILE_1): $(TARGET_OUT)
	$(vecho) "FW $@"
	$(Q) $(FW_TOOL) -eo $(TARGET_OUT) $(FW_FILE_1_ARGS)

$(FW_FILE_2): $(TARGET_OUT)
	$(vecho) "FW $@"
	$(Q) $(FW_TOOL) -eo $(TARGET_OUT) $(FW_FILE_2_ARGS)
	$(Q) $(MERGE_TOOL) $(FW_FILE_1) $(FW_FILE_2) firmware/app.bin

$(TARGET_OUT): $(APP_AR)
	$(vecho) "LD $@"
	$(Q) $(LD) -L$(SDK_LIBDIR) $(LD_SCRIPT) $(LDFLAGS) -Wl,--start-group $(LIBS) $(APP_AR) -Wl,--end-group -o $@

$(APP_AR): $(OBJ)
	$(vecho) "AR $@"
	$(Q) $(AR) cru $@ $^

build_ota1: checkdirs $(TARGET_OUT1) $(FW_FILE_U1_1) $(FW_FILE_U1_2) 

$(FW_FILE_U1_1): $(TARGET_OUT1)
	$(vecho) "FW $@"
	$(Q) $(FW_TOOL) -eo $(TARGET_OUT1) $(FW_USER1_1_ARGS)

$(FW_FILE_U1_2): $(TARGET_OUT1)
	$(vecho) "FW $@"
	$(Q) $(FW_TOOL) -eo $(TARGET_OUT1) $(FW_USER1_2_ARGS)
	$(Q) $(MERGE_TOOL) $(FW_FILE_U1_1) $(FW_FILE_U1_2) $(FW_FILE_U1)
	$(vecho) "CREATE " $(FW_FILE_U1_1) $(FW_FILE_U1_2) $(FW_FILE_U1)
	
$(TARGET_OUT1): $(APP_AR1)
	$(vecho) "LD $@"
	$(Q) $(LD) -L$(SDK_LIBDIR) $(LD_SCRIPT_U1) $(LDFLAGS) -Wl,--start-group $(LIBS) $(APP_AR1) -Wl,--end-group -o $@
	
$(APP_AR1): $(OBJ)
	$(vecho) "AR $@"
	$(Q) $(AR) cru $@ $^
	
	
build_ota2: checkdirs $(TARGET_OUT2) $(FW_FILE_U2_1) $(FW_FILE_U2_2)

$(FW_FILE_U2_1): $(TARGET_OUT2)
	$(vecho) "FW $@"
	$(Q) $(FW_TOOL) -eo $(TARGET_OUT2) $(FW_USER2_1_ARGS)

$(FW_FILE_U2_2): $(TARGET_OUT2)
	$(vecho) "FW $@"
	$(Q) $(FW_TOOL) -eo $(TARGET_OUT2) $(FW_USER2_2_ARGS)
	$(Q) $(MERGE_TOOL) $(FW_FILE_U2_1) $(FW_FILE_U2_2) $(FW_FILE_U2)
	$(vecho) "CREATE " $(FW_FILE_U2_1) $(FW_FILE_U2_2) $(FW_FILE_U2)

$(TARGET_OUT2): $(APP_AR2)
	$(vecho) "LD $@"
	$(Q) $(LD) -L$(SDK_LIBDIR) $(LD_SCRIPT_U2) $(LDFLAGS) -Wl,--start-group $(LIBS) $(APP_AR2) -Wl,--end-group -o $@

$(APP_AR2): $(OBJ)
	$(vecho) "AR $@"
	$(Q) $(AR) cru $@ $^

build_ota: clean build_ota1 build_ota2

upload_local:
	$(Q) node ota/upload.js $(CURDIR)/firmware/user1.bin $(CURDIR)/firmware/user2.bin "http://192.168.11.117" "192.168.11.117"

upload_cloud:
	$(Q) node ota/upload.js $(CURDIR)/firmware/user1.bin $(CURDIR)/firmware/user2.bin "http://otadomain.io" "otadomain.io"
		
checkdirs: $(BUILD_DIR) $(FW_BASE)

$(BUILD_DIR):
	$(Q) mkdir -p $@

firmware:
	$(Q) mkdir -p $@

flash: firmware/0x00000.bin firmware/0x40000.bin
	$(PYTHON) $(ESPTOOL) -p $(ESPPORT) write_flash 0x00000 firmware/0x00000.bin 0x40000 firmware/0x40000.bin

	
flash_ota: build_ota firmware/user1.bin firmware/user2.bin
	$(PYTHON) $(ESPTOOL) -p $(ESPPORT) write_flash 0x01000 firmware/user1.bin 0x41000 firmware/user2.bin
	
flash_ota_boot:
	$(PYTHON) $(ESPTOOL) -p $(ESPPORT) write_flash 0x00000 $(BOOTLOADER) 0x01000 firmware/user1_0x01000.bin 0x11000 firmware/user1_0x11000.bin 0x7E000  $(BLANKER)


test: flash
	screen $(ESPPORT) 115200

rebuild: clean all

clean:
	$(Q) rm -f $(APP_AR)
	$(Q) rm -f $(TARGET_OUT)
	$(Q) rm -rf $(BUILD_DIR)
	$(Q) rm -rf $(BUILD_BASE)
	$(Q) rm -f $(FW_FILE_1)
	$(Q) rm -f $(FW_FILE_2)
	$(Q) rm -rf $(FW_BASE)

$(foreach bdir,$(BUILD_DIR),$(eval $(call compile-objects,$(bdir))))
