TOP=$(shell pwd)
BUILD_DIR = Objects
TARGET = stm32_test
CORE_DIR = CORE
BIN_DIR = BIN

#设定包含文件目录
INC_FLAGS += -I $(TOP)/Library/CORE
INC_FLAGS += -I $(TOP)/Library/FWLIB/inc
INC_FLAGS += -I $(TOP)/User

CROSS_COMPILE=arm-none-eabi-
ASM=$(CROSS_COMPILE)gcc -W
CC=$(CROSS_COMPILE)gcc
CPP=$(CROSS_COMPILE)cpp
LD=$(CROSS_COMPILE)ld
HEX=$(CROSS_COMPILE)objcopy
OBJCOPY=$(CROSS_COMPILE)objcopy
OBJDUMP=$(CROSS_COMPILE)objdump

#######################################
# ASM sources
# 注意，如果使用.c的startup文件，请把下面两句注释掉，避免编译出现错误
#######################################
ASM_SOURCES =  $(CORE_DIR)/startup_stm32f10x_md.s

#######################################
# CFLAGS
#######################################
# debug build?
DEBUG = 1

# 代码优化级别
OPT = -Os

# cpu
CPU = -mcpu=cortex-m3

# fpu
# NONE for Cortex-M0/M0+/M3

# float-abi

# mcu
MCU = $(CPU) -mthumb $(FPU) $(FLOAT-ABI)

# C defines
# 这个地方的定义根据实际情况来，如果在代码里面有定义(如#define STM32F10X_HD)，这里可以不写
C_DEFS =  \
-D USE_STDPERIPH_DRIVER \
-D STM32F10X_MD

# PreProcess
CFLAGS =  -g $(MCU) $(C_DEFS) $(INC_FLAGS) $(OPT) -std=gnu99 -W -Wall -fdata-sections -ffunction-sections

#ifeq ($(DEBUG), 1)
#CFLAGS += -g -gdwarf-2
#endif
# 在$(BUILD_DIR)目录下生成依赖关系信息，依赖关系以.d结尾
CFLAGS += -MMD -MP -MF"$(addprefix $(BUILD_DIR)/, $(notdir $(@:%.o=%.d)))"

#######################################
# LDFLAGS
#######################################
# LD文件  
LDSCRIPT = STM32F10x.ld

# libraries
LIBS =
LIBDIR = 
LDFLAGS = $(MCU) -specs=nano.specs -T$(LDSCRIPT) $(LIBDIR) $(LIBS) -Wl,-Map=$(BUILD_DIR)/$(TARGET).map,--cref -Wl,--gc-sections

#######################################
# C/CPP源代码
#######################################
C_SRC = $(shell find ./ -name '*.c')
C_SRC += $(shell find ./ -name '*.cpp')

C_OBJ = $(addprefix $(BUILD_DIR)/,$(notdir $(C_SRC:%.c=%.o)))
vpath %.c $(sort $(dir $(C_SRC)))
#C_OBJ += $(ASM_SOURCES)
C_OBJ += $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_SOURCES:%.s=%.o)))
vpath %.s $(sort $(dir $(ASM_SOURCES)))


.PHONY: all clean update


all: $(BUILD_DIR)/$(TARGET).elf $(BIN_DIR)/$(TARGET).hex $(BIN_DIR)/$(TARGET).bin

# 从vpath中读取所有的.c文件，编译成.o文件
$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR)
	$(CC) -c $(CFLAGS) -Wa,-a,-ad,-alms=$(BUILD_DIR)/$(notdir $(<:.c=.lst)) -o $@ $<
# 从vpath中u读取所有的.s文件，编译成.o文件
$(BUILD_DIR)/%.o: $(CORE_DIR)/%.s | $(BUILD_DIR)
	$(ASM) -c $< -o $@

# 将所有的.o文件依据.ld文件，编译组成.elf文件
$(BUILD_DIR)/$(TARGET).elf: $(C_OBJ)
	$(LD)  -T $(LDSCRIPT) $(LIBS) $(C_OBJ)    -o $@ 

# 将.elf文件转为.hex格式
$(BIN_DIR)/%.hex: $(BUILD_DIR)/%.elf
	$(OBJCOPY) -O ihex $< $@
	
# 将.elf文件转为.bin格式
$(BIN_DIR)/%.bin: $(BUILD_DIR)/%.elf
	$(OBJCOPY) -O binary $< $@	

# 用于生成BUILD_DIR目录
$(BUILD_DIR):
	mkdir $@		

clean:
	rm -rf $(BUILD_DIR)/*