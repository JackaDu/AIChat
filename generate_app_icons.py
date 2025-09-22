#!/usr/bin/env python3
"""
AIChat 应用图标生成脚本
生成iOS应用所需的所有尺寸图标
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_app_icon(size, filename):
    """创建指定尺寸的应用图标"""
    # 创建图像
    img = Image.new('RGBA', (size, size), (0, 122, 255, 255))  # 蓝色背景
    draw = ImageDraw.Draw(img)
    
    # 绘制圆形背景
    margin = size // 10
    draw.ellipse([margin, margin, size-margin, size-margin], 
                 fill=(255, 255, 255, 255), outline=(0, 0, 0, 0))
    
    # 绘制文字 "AI"
    try:
        # 尝试使用系统字体
        font_size = size // 3
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
    except:
        # 如果系统字体不可用，使用默认字体
        font = ImageFont.load_default()
    
    # 计算文字位置
    text = "AI"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    x = (size - text_width) // 2
    y = (size - text_height) // 2 - size // 20
    
    # 绘制文字
    draw.text((x, y), text, fill=(0, 122, 255, 255), font=font)
    
    # 保存图标
    img.save(filename, 'PNG')
    print(f"✅ 生成图标: {filename} ({size}x{size})")

def main():
    """主函数"""
    print("🎨 开始生成AIChat应用图标...")
    
    # 图标尺寸配置
    icon_sizes = [
        # iPhone图标
        (40, "20@2x.png"),    # 20x20 @2x
        (60, "20@3x.png"),    # 20x20 @3x
        (58, "29@2x.png"),    # 29x29 @2x
        (87, "29@3x.png"),    # 29x29 @3x
        (80, "40@2x.png"),    # 40x40 @2x
        (120, "40@3x.png"),   # 40x40 @3x
        (120, "60@2x.png"),   # 60x60 @2x
        (180, "60@3x.png"),   # 60x60 @3x
        
        # iPad图标
        (20, "20.png"),       # 20x20 @1x
        (40, "20@2x.png"),    # 20x20 @2x (重复使用)
        (29, "29.png"),       # 29x29 @1x
        (58, "29@2x.png"),    # 29x29 @2x (重复使用)
        (40, "40.png"),       # 40x40 @1x
        (80, "40@2x.png"),    # 40x40 @2x (重复使用)
        (76, "76.png"),       # 76x76 @1x
        (152, "76@2x.png"),   # 76x76 @2x
        (167, "83.5@2x.png"), # 83.5x83.5 @2x
        
        # App Store图标
        (1024, "1024.png"),   # 1024x1024
    ]
    
    # 切换到图标目录
    icon_dir = "/Users/jackdu/Downloads/AIChat/AIChat/Assets.xcassets/AppIcon.appiconset"
    os.chdir(icon_dir)
    
    # 生成所有图标
    for size, filename in icon_sizes:
        create_app_icon(size, filename)
    
    print(f"\n🎉 所有图标生成完成！")
    print(f"📁 图标位置: {icon_dir}")
    print(f"📱 现在可以重新构建应用了")

if __name__ == "__main__":
    main()
