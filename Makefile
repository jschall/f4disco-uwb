GCC_DIR := /opt/gcc-arm-none-eabi-4_9-2015q3
LIBOPENCM3_DIR := submodules/libopencm3
LDSCRIPT := stm32f4.ld

ARCH_FLAGS := -mthumb -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16

LDFLAGS := --static -nostartfiles -L$(LIBOPENCM3_DIR)/lib -T$(LDSCRIPT) -Wl,--gc-sections --specs=rdimon.specs -u printf_float

LDLIBS := -lopencm3_stm32f3 -lm -Wl,--start-group -lc -lgcc -lrdimon -Wl,--end-group

CFLAGS += -std=gnu11 -O3 -ffast-math -g -Wdouble-promotion -Wextra -Wshadow -Wimplicit-function-declaration -Wredundant-decls -Wmissing-prototypes -Wstrict-prototypes -fsingle-precision-constant -fno-common -ffunction-sections -fdata-sections -MD -Wall -Wundef -Isrc -I$(LIBOPENCM3_DIR)/include -I$(LIBCANARD_DIR) -DSTM32F3

COMMON_OBJS := $(addprefix build/,$(addsuffix .o,$(basename $(shell find src/lib -name "*.c"))))
PROGS := $(addprefix build/bin/,$(addsuffix .elf,$(notdir $(basename $(shell ls src/programs/*.c)))))

.PHONY: all
all: $(LIBOPENCM3_DIR) $(PROGS)

build/bin/%.elf: $(COMMON_OBJS) build/src/programs/%.o
	@echo "### BUILDING $@"
	@mkdir -p "$(dir $@)"
	@arm-none-eabi-gcc $(LDFLAGS) $(ARCH_FLAGS) $^ $(LDLIBS) -o $@
	@arm-none-eabi-size $@

build/%.bin: build/%.elf
	@echo "### BUILDING $@"
	@mkdir -p "$(dir $@)"
	@arm-none-eabi-objcopy -O binary $< $@

build/src/%.o: src/%.c $(LIBOPENCM3_DIR)
	@echo "### BUILDING $@"
	@mkdir -p "$(dir $@)"
	@arm-none-eabi-gcc $(CFLAGS) $(ARCH_FLAGS) -c $< -o $@

.PHONY: $(LIBOPENCM3_DIR)
$(LIBOPENCM3_DIR):
	@echo "### BUILDING $@"
	echo "$(PROGS)"
	@$(MAKE) -C $(LIBOPENCM3_DIR)

.PHONY: upload
%-upload: build/bin/%.elf
	@echo "### UPLOADING"
	@openocd -f openocd.cfg -c "program $< verify reset exit"

.PHONY: clean
clean:
	@$(MAKE) -C $(LIBOPENCM3_DIR) clean
	@rm -rf build