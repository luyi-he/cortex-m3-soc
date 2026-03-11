# Cortex-M3 SoC 固件 Makefile
# ============================================================================

# 工具链 (GNU Arm Embedded Toolchain)
PREFIX = arm-none-eabi-
CC = $(PREFIX)gcc
AS = $(PREFIX)gcc
LD = $(PREFIX)gcc
OBJCOPY = $(PREFIX)objcopy
OBJDUMP = $(PREFIX)objdump
SIZE = $(PREFIX)size

# 项目设置
PROJECT = cortex-m3-firmware
BUILD_DIR = build
SRC_DIR = src
INC_DIR = include
SCRIPTS_DIR = scripts

# 目标芯片
CPU = -mcpu=cortex-m3
FPU =
FLOAT-ABI =

# 编译选项
MCU = $(CPU) -mthumb $(FPU) $(FLOAT-ABI)
CFLAGS = $(MCU) -Wall -Os -g3
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -I$(INC_DIR)
CFLAGS += -I$(SRC_DIR)
CFLAGS += -I.

# 汇编选项
ASFLAGS = $(MCU) -Wall -g3

# 链接选项
LDSCRIPT = $(SCRIPTS_DIR)/linker.ld
LDFLAGS = $(MCU) -T$(LDSCRIPT)
LDFLAGS += -Wl,--gc-sections
LDFLAGS += -Wl,-Map=$(BUILD_DIR)/$(PROJECT).map

# 源文件
C_SOURCES = $(wildcard $(SRC_DIR)/*.c)
C_SOURCES += $(wildcard drivers/*.c)
ASM_SOURCES = $(wildcard $(SRC_DIR)/*.s)

# 排除 main.c 和 examples.c（bootloader 不需要）
C_SOURCES := $(filter-out $(SRC_DIR)/main.c,$(C_SOURCES))
C_SOURCES := $(filter-out $(SRC_DIR)/examples.c,$(C_SOURCES))

# 目标文件
OBJECTS = $(addprefix $(BUILD_DIR)/,$(notdir $(C_SOURCES:.c=.o)))
vpath %.c $(SRC_DIR) drivers
OBJECTS += $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_SOURCES:.s=.o)))
vpath %.s $(SRC_DIR)

# 默认目标
all: $(BUILD_DIR)/$(PROJECT).elf $(BUILD_DIR)/$(PROJECT).bin $(BUILD_DIR)/$(PROJECT).hex size

# 创建输出目录
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# 编译 C 文件
$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# 编译汇编文件
$(BUILD_DIR)/%.o: %.s | $(BUILD_DIR)
	$(AS) $(ASFLAGS) -c $< -o $@

# 链接
$(BUILD_DIR)/$(PROJECT).elf: $(OBJECTS)
	$(LD) $(LDFLAGS) $^ -o $@

# 生成 BIN 文件
$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf
	$(OBJCOPY) -O binary $< $@

# 生成 HEX 文件
$(BUILD_DIR)/%.hex: $(BUILD_DIR)/%.elf
	$(OBJCOPY) -O ihex $< $@

# 显示大小
size: $(BUILD_DIR)/$(PROJECT).elf
	$(SIZE) -A $<

# 反汇编
disasm: $(BUILD_DIR)/$(PROJECT).elf
	$(OBJDUMP) -d -S $< > $(BUILD_DIR)/$(PROJECT).lst

# 清理
clean:
	rm -rf $(BUILD_DIR)

# 烧录 (OpenOCD)
flash: $(BUILD_DIR)/$(PROJECT).elf
	openocd -f interface/stlink.cfg -f target/stm32.cfg -c "program $< verify reset exit"

# 调试 (GDB)
debug: $(BUILD_DIR)/$(PROJECT).elf
	openocd -f interface/stlink.cfg -f target/stm32.cfg &
	$(PREFIX)gdb $< -ex "target remote :3333" -ex "monitor reset halt"

# 打印帮助
help:
	@echo "Cortex-M3 SoC Firmware Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all      - Build ELF, BIN, HEX files (default)"
	@echo "  clean    - Remove build files"
	@echo "  flash    - Flash to target via OpenOCD"
	@echo "  debug    - Start GDB debugging session"
	@echo "  disasm   - Generate disassembly listing"
	@echo "  size     - Show memory usage"
	@echo "  help     - Show this help"
	@echo ""
	@echo "Configuration:"
	@echo "  CPU      = $(CPU)"
	@echo "  CFLAGS   = $(CFLAGS)"
	@echo "  LDFLAGS  = $(LDFLAGS)"

.PHONY: all clean flash debug disasm size help
