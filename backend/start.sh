#!/bin/bash

# YouTube 字幕服务启动脚本

echo "=================================="
echo "🚀 启动 YouTube 字幕服务"
echo "=================================="

# 检查 Python 是否安装
if ! command -v python3 &> /dev/null; then
    echo "❌ 错误: 未找到 Python 3"
    echo "请先安装 Python 3: https://www.python.org/downloads/"
    exit 1
fi

echo "✅ Python 版本: $(python3 --version)"

# 检查依赖是否已安装
if ! python3 -c "import flask" 2>/dev/null; then
    echo "📦 安装依赖..."
    pip3 install -r requirements.txt
    
    if [ $? -ne 0 ]; then
        echo "❌ 依赖安装失败"
        exit 1
    fi
    echo "✅ 依赖安装完成"
else
    echo "✅ 依赖已安装"
fi

# 启动服务
echo ""
echo "🎬 启动服务..."
python3 app.py
