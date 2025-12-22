"""
Gunicorn 配置文件
用于生产环境部署
"""

import os
import multiprocessing

# 服务器绑定地址
bind = f"0.0.0.0:{os.getenv('PORT', '5001')}"

# Worker 进程数 (免费套餐建议使用 1 个)
workers = 1

# 每个 worker 的线程数
threads = 2

# Worker 类型
worker_class = "sync"

# 超时时间 (秒)
timeout = 120

# 保持连接时间
keepalive = 5

# 日志级别
loglevel = "info"

# 访问日志格式
accesslog = "-"
errorlog = "-"

# 优雅重启超时
graceful_timeout = 30

# 预加载应用
preload_app = True
