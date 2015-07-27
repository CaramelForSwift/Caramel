# A simple build script for building projects.
#
# usage: make [CONFIG=debug|release]

LIB_MODULE_NAME = Jelly
TEST_MODULE_NAME = TestServer

SDK         = macosx
ARCH        = x86_64

CONFIG     ?= debug

ROOT_DIR    = $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
OUTPUT_DIR  = $(ROOT_DIR)/bin
TARGET_DIR  = $(OUTPUT_DIR)/$(SDK)/$(CONFIG)
LIB_SRC_DIR = $(ROOT_DIR)/Server
TEST_SRC_DIR = $(ROOT_DIR)/Test

ifeq ($(CONFIG), debug)
    CFLAGS=-Onone -g
else
    CFLAGS=-O3
endif

SWIFTC      = $(shell xcrun -f swiftc)
CLANG       = $(shell xcrun -f clang)
SDK_PATH    = $(shell xcrun --show-sdk-path --sdk $(SDK))
LIB_SWIFT_FILES = $(shell find $(LIB_SRC_DIR) -name "*.swift")
TEST_SWIFT_FILES = $(wildcard $(TEST_SRC_DIR)/*.swift)

LIBRARY_BUILD_PATH = $(TARGET_DIR)/lib$(LIB_MODULE_NAME).a
TEST_BUILD_PATH = $(TARGET_DIR)/$(TEST_MODULE_NAME)

build: build-lib build-test

setup_base_dir:
	mkdir -p $(TARGET_DIR)

build-lib: setup_base_dir
	$(SWIFTC) $(LIB_SWIFT_FILES) -emit-library -sdk $(SDK_PATH) -module-name $(LIB_MODULE_NAME) -emit-module -emit-module-path $(TARGET_DIR)/$(LIB_MODULE_NAME).swiftmodule -o $(LIBRARY_BUILD_PATH)

build-test: setup_base_dir
	$(SWIFTC) $(TEST_SWIFT_FILES) -emit-executable -sdk $(SDK_PATH) -module-name $(TEST_MODULE_NAME) -I$(TARGET_DIR) -L$(TARGET_DIR) -l$(LIB_MODULE_NAME) -emit-module -emit-module-path $(TARGET_DIR)/$(TEST_MODULE_NAME).swiftmodule -o $(TEST_BUILD_PATH)

clean:
	rm -rf $(TARGET_DIR)

nuke:
	rm -rf $(OUTPUT_DIR)
