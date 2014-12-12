## Clang configurations.

# WITHOUT_CLANG covers both HOST and TARGET
ifeq ($(WITHOUT_CLANG),true)
WITHOUT_TARGET_CLANG := true
WITHOUT_HOST_CLANG := true
endif

LLVM_PREBUILTS_VERSION := 3.6
LLVM_PREBUILTS_PATH := prebuilts/clang/$(BUILD_OS)-x86/host/$(LLVM_PREBUILTS_VERSION)/bin
LLVM_RTLIB_PATH := $(LLVM_PREBUILTS_PATH)/../lib/clang/$(LLVM_PREBUILTS_VERSION)/lib/linux/

CLANG := $(LLVM_PREBUILTS_PATH)/clang$(BUILD_EXECUTABLE_SUFFIX)
CLANG_CXX := $(LLVM_PREBUILTS_PATH)/clang++$(BUILD_EXECUTABLE_SUFFIX)
LLVM_AS := $(LLVM_PREBUILTS_PATH)/llvm-as$(BUILD_EXECUTABLE_SUFFIX)
LLVM_LINK := $(LLVM_PREBUILTS_PATH)/llvm-link$(BUILD_EXECUTABLE_SUFFIX)

CLANG_TBLGEN := $(BUILD_OUT_EXECUTABLES)/clang-tblgen$(BUILD_EXECUTABLE_SUFFIX)
LLVM_TBLGEN := $(BUILD_OUT_EXECUTABLES)/llvm-tblgen$(BUILD_EXECUTABLE_SUFFIX)

# The C/C++ compiler can be wrapped by setting the CC/CXX_WRAPPER vars.
ifdef CC_WRAPPER
  ifneq ($(CC_WRAPPER),$(firstword $(CLANG)))
    CLANG := $(CC_WRAPPER) $(CLANG)
  endif
endif
ifdef CXX_WRAPPER
  ifneq ($(CXX_WRAPPER),$(firstword $(CLANG_CXX)))
    CLANG_CXX := $(CXX_WRAPPER) $(CLANG_CXX)
  endif
endif

# Clang flags for all host or target rules
CLANG_CONFIG_EXTRA_ASFLAGS :=
CLANG_CONFIG_EXTRA_CFLAGS :=
CLANG_CONFIG_EXTRA_CONLYFLAGS := -std=gnu99
CLANG_CONFIG_EXTRA_CPPFLAGS :=
CLANG_CONFIG_EXTRA_LDFLAGS :=

CLANG_CONFIG_EXTRA_CFLAGS += \
  -D__compiler_offsetof=__builtin_offsetof

# Help catch common 32/64-bit errors.
CLANG_CONFIG_EXTRA_CFLAGS += \
  -Werror=int-conversion

# Disable overly aggressive warning for macros defined with a leading underscore
# This happens in AndroidConfig.h, which is included nearly everywhere.
CLANG_CONFIG_EXTRA_CFLAGS += \
  -Wno-reserved-id-macro

# Workaround for ccache with clang.
# See http://petereisentraut.blogspot.com/2011/05/ccache-and-clang.html.
CLANG_CONFIG_EXTRA_CFLAGS += \
  -Wno-unused-command-line-argument

# Disable -Winconsistent-missing-override until we can clean up the existing
# codebase for it.
CLANG_CONFIG_EXTRA_CPPFLAGS += \
  -Wno-inconsistent-missing-override

CLANG_CONFIG_UNKNOWN_CFLAGS := \
  -finline-functions \
  -finline-limit=64 \
  -fno-canonical-system-headers \
  -fno-tree-sra \
  -fprefetch-loop-arrays \
  -funswitch-loops \
  -Wmaybe-uninitialized \
  -Wno-error=maybe-uninitialized \
  -Wno-error=unused-but-set-parameter \
  -Wno-error=unused-but-set-variable \
  -Wno-free-nonheap-object \
  -Wno-literal-suffix \
  -Wno-maybe-uninitialized \
  -Wno-old-style-declaration \
  -Wno-psabi \
  -Wno-unused-but-set-parameter \
  -Wno-unused-but-set-variable \
  -Wno-unused-local-typedefs \
  -Wunused-but-set-parameter \
  -Wunused-but-set-variable

# Clang flags for all host rules
CLANG_CONFIG_HOST_EXTRA_ASFLAGS :=
CLANG_CONFIG_HOST_EXTRA_CFLAGS :=
CLANG_CONFIG_HOST_EXTRA_CPPFLAGS :=
CLANG_CONFIG_HOST_EXTRA_LDFLAGS :=

# Clang flags for all target rules
CLANG_CONFIG_TARGET_EXTRA_ASFLAGS :=
CLANG_CONFIG_TARGET_EXTRA_CFLAGS := -nostdlibinc
CLANG_CONFIG_TARGET_EXTRA_CPPFLAGS := -nostdlibinc
CLANG_CONFIG_TARGET_EXTRA_LDFLAGS :=

# HOST config
clang_2nd_arch_prefix :=
include $(BUILD_SYSTEM)/clang/HOST_$(HOST_ARCH).mk

# HOST_2ND_ARCH config
ifdef HOST_2ND_ARCH
clang_2nd_arch_prefix := $(HOST_2ND_ARCH_VAR_PREFIX)
include $(BUILD_SYSTEM)/clang/HOST_$(HOST_2ND_ARCH).mk
endif

# TARGET config
clang_2nd_arch_prefix :=
include $(BUILD_SYSTEM)/clang/TARGET_$(TARGET_ARCH).mk

# TARGET_2ND_ARCH config
ifdef TARGET_2ND_ARCH
clang_2nd_arch_prefix := $(TARGET_2ND_ARCH_VAR_PREFIX)
include $(BUILD_SYSTEM)/clang/TARGET_$(TARGET_2ND_ARCH).mk
endif

# Address sanitizer clang config
ADDRESS_SANITIZER_RUNTIME_LIBRARY := libclang_rt.asan_$(TARGET_ARCH)_android
ADDRESS_SANITIZER_CONFIG_EXTRA_CFLAGS := -fno-omit-frame-pointer
ADDRESS_SANITIZER_CONFIG_EXTRA_LDFLAGS := -Wl,-u,__asan_preinit

ADDRESS_SANITIZER_CONFIG_EXTRA_SHARED_LIBRARIES := libdl $(ADDRESS_SANITIZER_RUNTIME_LIBRARY)
ADDRESS_SANITIZER_CONFIG_EXTRA_STATIC_LIBRARIES := libasan

# This allows us to use the superset of functionality that compiler-rt
# provides to Clang (for supporting features like -ftrapv).
COMPILER_RT_CONFIG_EXTRA_STATIC_LIBRARIES := libcompiler_rt-extras

ifeq ($(HOST_PREFER_32_BIT),true)
# We don't have 32-bit prebuilt libLLVM/libclang, so force to build them from source.
FORCE_BUILD_LLVM_COMPONENTS := true
endif
