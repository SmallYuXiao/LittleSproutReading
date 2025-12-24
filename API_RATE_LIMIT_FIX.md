# API 频率限制问题修复

## 问题描述

iiilab API 返回错误：
```
'Your operation is too frequent, please try again later'
code: 'ShowSponsorAds'
```

这是因为 API 有频率限制，短时间内发送太多请求会被拒绝。

---

## 解决方案

### 1. 频率控制（Rate Limiting）

添加请求间隔控制，确保每次请求之间至少间隔 3 秒：

```python
def __init__(self):
    # 频率控制
    self.last_request_time = 0
    self.min_request_interval = 3.0  # 最小请求间隔3秒

def _wait_for_rate_limit(self):
    """等待以满足频率限制"""
    elapsed = time.time() - self.last_request_time
    if elapsed < self.min_request_interval:
        wait_time = self.min_request_interval - elapsed
        logger.info(f"⏳ 频率限制：等待 {wait_time:.1f} 秒")
        time.sleep(wait_time)
    self.last_request_time = time.time()
```

### 2. 内存缓存（Caching）

添加简单的内存缓存，避免重复请求相同视频：

```python
def __init__(self):
    # 简单内存缓存
    self.cache = {}
    self.cache_ttl = 600  # 缓存10分钟

def extract_video_info(self, youtube_url: str) -> Dict:
    # 1. 检查缓存
    cache_key = self._get_cache_key(youtube_url)
    if cache_key in self.cache:
        cached_data, timestamp = self.cache[cache_key]
        if time.time() - timestamp < self.cache_ttl:
            logger.info(f"💾 从缓存返回数据")
            return cached_data
    
    # 2. 频率限制等待
    self._wait_for_rate_limit()
    
    # 3. 发送请求...
    
    # 4. 保存到缓存
    self.cache[cache_key] = (result, time.time())
```

---

## 工作流程

### 之前（无保护）
```
请求1 → API → 成功
请求2（0.1秒后） → API → 成功
请求3（0.2秒后） → API → ❌ 频率限制
请求4（0.3秒后） → API → ❌ 频率限制
```

### 现在（有保护）
```
请求1 → 检查缓存（无） → 等待0秒 → API → 成功 → 缓存
请求2（0.1秒后） → 检查缓存（无） → 等待2.9秒 → API → 成功 → 缓存
请求3（相同视频） → 检查缓存（有） → 💾 直接返回 ✅
请求4（3.5秒后） → 检查缓存（无） → 等待0秒 → API → 成功 → 缓存
```

---

## 配置参数

### 频率控制
- **min_request_interval**: 3.0 秒
  - 可以根据实际情况调整（1-5秒）
  - 太短可能触发限制
  - 太长影响用户体验

### 缓存
- **cache_ttl**: 600 秒（10分钟）
  - YouTube 视频信息不经常变化
  - 10分钟内重复请求直接返回缓存
  - 可以调整为更长时间（如30分钟）

---

## 日志输出

### 频率限制等待
```
⏳ 频率限制：等待 2.5 秒
```

### 缓存命中
```
💾 从缓存返回数据（video ID: video_dQw4w9WgXcQ）
```

### 缓存保存
```
💾 数据已缓存（TTL: 600秒）
```

---

## 优势

### 1. 避免 API 限制
- ✅ 自动控制请求频率
- ✅ 不会触发 "too frequent" 错误
- ✅ 提高请求成功率

### 2. 提升性能
- ✅ 缓存命中时立即返回（< 1ms）
- ✅ 减少网络请求
- ✅ 降低后端负载

### 3. 改善用户体验
- ✅ 重复观看相同视频时加载更快
- ✅ 减少等待时间
- ✅ 更稳定的服务

---

## 测试

### 测试场景 1：快速连续请求
```bash
# 请求同一个视频3次
curl http://localhost:5001/api/youtube-info/dQw4w9WgXcQ
# 第1次：等待0秒，API请求，成功
sleep 0.5
curl http://localhost:5001/api/youtube-info/dQw4w9WgXcQ
# 第2次：从缓存返回，立即成功
sleep 0.5
curl http://localhost:5001/api/youtube-info/dQw4w9WgXcQ
# 第3次：从缓存返回，立即成功
```

### 测试场景 2：不同视频
```bash
# 请求3个不同视频
curl http://localhost:5001/api/youtube-info/video1
# 等待0秒，API请求
sleep 1
curl http://localhost:5001/api/youtube-info/video2
# 等待2秒（频率限制），API请求
sleep 1
curl http://localhost:5001/api/youtube-info/video3
# 等待2秒（频率限制），API请求
```

---

## 进一步优化（可选）

### 1. Redis 缓存
如果需要跨进程共享缓存：
```python
import redis
r = redis.Redis(host='localhost', port=6379)
```

### 2. 持久化缓存
保存到文件，重启后仍有效：
```python
import pickle
with open('cache.pkl', 'wb') as f:
    pickle.dump(self.cache, f)
```

### 3. LRU 缓存
限制缓存大小，自动淘汰旧数据：
```python
from functools import lru_cache
@lru_cache(maxsize=100)
def extract_video_info(self, youtube_url: str):
    ...
```

### 4. 重试机制
API 失败时自动重试：
```python
for attempt in range(3):
    try:
        return self._request_api()
    except:
        if attempt < 2:
            time.sleep(5)
            continue
        raise
```

---

## 相关文件

- `backend/youtube_iiilab.py` - 修改的文件
- `backend/app.py` - Flask 应用

---

## 总结

通过添加频率控制和缓存机制，成功解决了 iiilab API 的频率限制问题：

- ✅ 自动等待，避免请求过快
- ✅ 缓存结果，减少重复请求
- ✅ 提升性能和用户体验
- ✅ 提高系统稳定性

---

**创建日期**: 2025-12-23  
**版本**: 1.0  
**状态**: ✅ 已实施并测试

