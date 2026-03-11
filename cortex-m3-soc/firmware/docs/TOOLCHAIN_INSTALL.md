# 工具链安装指南

## macOS

### 使用 Homebrew (推荐)

```bash
# 安装 Homebrew (如果未安装)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装 ARM 工具链
brew install arm-none-eabi-gcc

# 验证安装
arm-none-eabi-gcc --version
```

### 手动安装

1. 从 [ARM 官网](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads) 下载
2. 解压到 `/Applications/ARM/`
3. 添加到 PATH:
```bash
export PATH="/Applications/ARM/gcc-arm-none-eabi-*/bin:$PATH"
```

## Ubuntu/Debian

```bash
# 安装工具链
sudo apt-get update
sudo apt-get install gcc-arm-none-eabi binutils-arm-none-eabi

# 验证安装
arm-none-eabi-gcc --version
```

## Fedora/RHEL

```bash
sudo dnf install arm-none-eabi-gcc-cs arm-none-eabi-newlib
```

## Windows

1. 从 [ARM 官网](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads) 下载 Windows 安装包
2. 运行安装程序
3. 添加到系统 PATH: `C:\Program Files (x86)\GNU Tools Arm Embedded\*\bin`

或使用 Chocolatey:

```powershell
choco install gcc-arm-embedded
```

## OpenOCD (可选，用于烧录)

### macOS

```bash
brew install openocd
```

### Ubuntu/Debian

```bash
sudo apt-get install openocd
```

### Windows

从 [OpenOCD 官网](http://openocd.org/pages/getting-openocd.html) 下载

## 验证安装

```bash
# 检查编译器
arm-none-eabi-gcc --version

# 检查工具链
arm-none-eabi-objcopy --version
arm-none-eabi-gdb --version

# 检查 OpenOCD (如果安装)
openocd --version
```

## 编译测试

```bash
cd ~/.openclaw/workspace/cortex-m3-soc/firmware
make clean
make
```

成功输出示例：

```
arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb ... -c startup.c -o build/startup.o
...
arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb ... -o build/firmware.elf
arm-none-eabi-objcopy -O binary build/firmware.elf build/firmware.bin
```

## 常见问题

### 权限问题 (macOS/Linux)

```bash
sudo chown -R $(whoami) /usr/local/bin/arm-none-eabi-*
```

### PATH 问题

确保工具链在 PATH 中：

```bash
echo $PATH
```

添加到 `~/.zshrc` 或 `~/.bashrc`:

```bash
export PATH="/usr/local/bin:$PATH"
```

### 缺少库 (Linux)

```bash
# Ubuntu/Debian
sudo apt-get install libusb-1.0-0-dev libftdi1-dev

# Fedora
sudo dnf install libusb1-devel libftdi-devel
```
