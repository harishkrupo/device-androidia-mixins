ifneq ($(TARGET_PREBUILT_KERNEL),)
$(error TARGET_PREBUILT_KERNEL defined but AndroidIA kernels build from source)
endif

TARGET_KERNEL_SRC ?= kernel/android_ia

{{#x86_64}}
TARGET_KERNEL_ARCH := x86_64
TARGET_KERNEL_CONFIG ?= kernel_64_defconfig
{{/x86_64}}

{{^x86_64}}
$(error 32bit Kernel builds are not supported.)
{{/x86_64}}

KERNEL_CONFIG_DIR := {{{kernel_config_dir}}}

KERNEL_NAME := bzImage

# Set the output for the kernel build products.
KERNEL_OUT := $(abspath $(TARGET_OUT_INTERMEDIATES)/kernel)
KERNEL_BIN := $(KERNEL_OUT)/arch/$(TARGET_KERNEL_ARCH)/boot/$(KERNEL_NAME)

KERNELRELEASE = $(shell cat $(KERNEL_OUT)/include/config/kernel.release)

build_kernel := $(MAKE) -C $(TARGET_KERNEL_SRC) \
		O=$(KERNEL_OUT) \
		ARCH=$(TARGET_KERNEL_ARCH) \
		CROSS_COMPILE="$(KERNEL_CROSS_COMPILE_WRAPPER)" \
		KCFLAGS="$(KERNEL_CFLAGS)" \
		KAFLAGS="$(KERNEL_AFLAGS)" \
		$(if $(SHOW_COMMANDS),V=1) \
		INSTALL_MOD_PATH=$(abspath $(TARGET_OUT))

KERNEL_CONFIG_FILE := device/intel/android_ia/kernel_config/$(TARGET_KERNEL_CONFIG)

KERNEL_CONFIG := $(KERNEL_OUT)/.config
$(KERNEL_CONFIG): $(KERNEL_CONFIG_FILE)
	$(hide) mkdir -p $(@D) && cat $(wildcard $^) > $@
	$(build_kernel) oldnoconfig

# Produces the actual kernel image!
$(PRODUCT_OUT)/kernel: $(KERNEL_CONFIG) | $(ACP)
	$(build_kernel) $(KERNEL_NAME)
	$(hide) $(ACP) -fp $(KERNEL_BIN) $@

installclean: FILES += $(KERNEL_OUT) $(PRODUCT_OUT)/kernel

.PHONY: kernel
kernel: $(PRODUCT_OUT)/kernel

#Firmware
SYMLINKS := $(subst $(FIRMWARES_DIR),$(TARGET_OUT)/etc/firmware,$(filter-out $(FIRMWARES_DIR)/$(FIRMWARE_FILTERS),$(shell find $(FIRMWARES_DIR) -type l)))

$(SYMLINKS): FW_PATH := $(FIRMWARES_DIR)
$(SYMLINKS):
	@link_to=`readlink $(subst $(TARGET_OUT)/etc/firmware,$(FW_PATH),$@)`; \
	echo "Symlink: $@ -> $$link_to"; \
	mkdir -p $(@D); ln -sf $$link_to $@

ALL_DEFAULT_INSTALLED_MODULES += $(SYMLINKS)
