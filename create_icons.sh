#!/bin/bash

# AIChat 应用图标生成脚本
# 使用macOS自带的sips工具生成所需尺寸的图标

echo "🎨 开始生成AIChat应用图标..."

# 创建临时的基础图标 (1024x1024)
echo "📱 创建基础图标..."
sips -s format png -z 1024 1024 /System/Library/PrivateFrameworks/LoginUIKit.framework/Resources/apple_logo_black.png --out temp_1024.png 2>/dev/null || {
    # 如果上面的命令失败，创建一个简单的彩色方块
    sips -s format png -z 1024 1024 /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns --out temp_1024.png 2>/dev/null || {
        # 如果还是失败，创建一个纯色图标
        echo "创建纯色图标..."
        sips -s format png -s dpiHeight 72 -s dpiWidth 72 -z 1024 1024 /System/Library/PrivateFrameworks/LoginUIKit.framework/Resources/apple_logo_black.png --out temp_1024.png 2>/dev/null || {
            # 最后的备用方案
            echo "使用备用方案创建图标..."
            # 创建一个简单的蓝色方块作为图标
            python3 -c "
from PIL import Image, ImageDraw
import sys
try:
    img = Image.new('RGBA', (1024, 1024), (0, 122, 255, 255))
    draw = ImageDraw.Draw(img)
    margin = 100
    draw.ellipse([margin, margin, 1024-margin, 1024-margin], fill=(255, 255, 255, 255))
    draw.text((400, 400), 'AI', fill=(0, 122, 255, 255))
    img.save('temp_1024.png', 'PNG')
    print('✅ 基础图标创建成功')
except Exception as e:
    print(f'❌ 图标创建失败: {e}')
    sys.exit(1)
"
        }
    }
}

# 生成各种尺寸的图标
echo "📏 生成各种尺寸图标..."

# iPhone图标
sips -z 40 40 temp_1024.png --out 20@2x.png
sips -z 60 60 temp_1024.png --out 20@3x.png
sips -z 58 58 temp_1024.png --out 29@2x.png
sips -z 87 87 temp_1024.png --out 29@3x.png
sips -z 80 80 temp_1024.png --out 40@2x.png
sips -z 120 120 temp_1024.png --out 40@3x.png
sips -z 120 120 temp_1024.png --out 60@2x.png
sips -z 180 180 temp_1024.png --out 60@3x.png

# iPad图标
sips -z 20 20 temp_1024.png --out 20.png
sips -z 29 29 temp_1024.png --out 29.png
sips -z 40 40 temp_1024.png --out 40.png
sips -z 76 76 temp_1024.png --out 76.png
sips -z 152 152 temp_1024.png --out 76@2x.png
sips -z 167 167 temp_1024.png --out 83.5@2x.png

# App Store图标
cp temp_1024.png 1024.png

# 清理临时文件
rm temp_1024.png

echo "✅ 所有图标生成完成！"
echo "📁 图标位置: $(pwd)"
echo "📱 现在可以重新构建应用了"

# 显示生成的图标列表
echo ""
echo "📋 生成的图标列表:"
ls -la *.png
