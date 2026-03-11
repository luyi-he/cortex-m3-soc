#!/bin/bash
# 设置 Surfer 为默认 VCD 查看器

echo "Setting Surfer as default VCD viewer..."

# 创建 ~/.MacOSX/环境配置
mkdir -p ~/.MacOSX

# 创建 LS 关联
cat > ~/.MacOSX/com.apple.LaunchServices/com.apple.launchservices.secure.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>LSHandlers</key>
    <array>
        <dict>
            <key>LSHandlerContentTag</key>
            <string>vcd</string>
            <key>LSHandlerContentTagClass</key>
            <string>public.filename-extension</string>
            <key>LSHandlerRoleAll</key>
            <string>org.msoffice.surfer</string>
        </dict>
    </array>
</dict>
</plist>
EOF

echo "✓ Created LaunchServices configuration"
echo ""
echo "To complete the setup:"
echo "1. Right-click on any .vcd file"
echo "2. Select 'Get Info'"
echo "3. Under 'Open with:', select 'Surfer'"
echo "4. Click 'Change All...'"
echo ""
echo "Or use the command:"
echo "  open -a Surfer cortex-m3-soc/sim/tb_gpio_ctrl.vcd"
