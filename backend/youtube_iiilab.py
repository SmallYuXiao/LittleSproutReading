#!/usr/bin/env python3
"""
iiiLab YouTube 视频解析服务集成
提供通过 iiilab.com 服务获取 YouTube 视频直接播放地址的功能
"""

import requests
import hashlib
import time
import logging
from typing import Dict, List, Optional

logger = logging.getLogger(__name__)


class IIILabYouTubeService:
    """iiiLab YouTube 解析服务封装类（使用新 API）"""
    
    # 新 API 地址和密钥（来自 iiiLabCrawler 开源项目）
    BASE_URL = "https://api.snapany.com/v1/extract"
    SALT = "6HTugjCXxR"  # 新 API 的密钥
    
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        })
        
        # 频率控制
        self.last_request_time = 0
        self.min_request_interval = 3.0  # 最小请求间隔3秒
        
        # 简单内存缓存
        self.cache = {}
        self.cache_ttl = 600  # 缓存10分钟
    
    def _generate_signature(self, timestamp: int, url: str, language: str = "en") -> str:
        """
        生成请求签名 (G-Footer)
        
        算法（基于 iiiLabCrawler 开源项目）:
        G-Footer = md5(url + language + timestamp + salt)
        
        参数:
            timestamp: Unix 时间戳（毫秒）
            url: YouTube 视频完整 URL
            language: 语言代码，默认为 "en"
        
        返回:
            32 位 MD5 签名字符串
        """
        # 签名字符串: url + language + timestamp + salt
        signature_string = f"{url}{language}{timestamp}{self.SALT}"
        
        # 计算 MD5 哈希
        signature = hashlib.md5(signature_string.encode()).hexdigest()
        
        
        return signature
    
    def _wait_for_rate_limit(self):
        """等待以满足频率限制"""
        elapsed = time.time() - self.last_request_time
        if elapsed < self.min_request_interval:
            wait_time = self.min_request_interval - elapsed
            time.sleep(wait_time)
        self.last_request_time = time.time()
    
    def _get_cache_key(self, youtube_url: str) -> str:
        """生成缓存键"""
        # 提取 video ID 作为缓存键
        import re
        match = re.search(r'(?:v=|/)([0-9A-Za-z_-]{11})', youtube_url)
        if match:
            return f"video_{match.group(1)}"
        return f"video_{hashlib.md5(youtube_url.encode()).hexdigest()}"
    
    def extract_video_info(self, youtube_url: str) -> Dict:
        """
        提取 YouTube 视频信息（带缓存和频率控制）
        
        Args:
            youtube_url: YouTube 视频 URL
            
        Returns:
            包含视频信息的字典
        """
        # 1. 检查缓存
        cache_key = self._get_cache_key(youtube_url)
        if cache_key in self.cache:
            cached_data, timestamp = self.cache[cache_key]
            if time.time() - timestamp < self.cache_ttl:
                return cached_data
            else:
                # 缓存过期
                del self.cache[cache_key]
        
        # 2. 频率限制等待
        self._wait_for_rate_limit()
        
        try:
            # 使用毫秒级时间戳（新 API 要求）
            timestamp = int(time.time() * 1000)
            language = "en"  # 语言代码
            
            # 准备请求数据（新 API 使用 link 参数）
            payload = {
                "link": youtube_url
            }
            
            # 添加签名头
            signature = self._generate_signature(timestamp, youtube_url, language)
            headers = {
                'G-Timestamp': str(timestamp),
                'G-Footer': signature,
                'Accept-Language': language,  # 新 API 要求
            }
            
            
            # 调试：输出请求详情
            
            # 发送请求
            response = self.session.post(
                self.BASE_URL,
                json=payload,
                headers=headers,
                timeout=30
            )
            
            # 调试：输出响应详情
            
            # 如果是 400 错误,记录响应内容
            if response.status_code == 400:
                try:
                    error_data = response.json()
                    logger.error(f"API 400 错误: {error_data}")
                except:
                    pass
            
            response.raise_for_status()
            data = response.json()
            
            # 调试：输出完整响应
            
            # API 直接返回数据，没有 code/msg 包装
            if 'text' in data or 'medias' in data:
                result = self._parse_response(data)
                
                # 3. 保存到缓存
                self.cache[cache_key] = (result, time.time())
                
                return result
            else:
                # 如果有错误信息
                error_msg = data.get('msg') or data.get('error') or data.get('message') or 'Unknown error'
                raise Exception(f"API 返回错误: {error_msg}")
                
        except requests.exceptions.RequestException as e:
            raise Exception(f"网络请求失败: {str(e)}")
        except Exception as e:
            raise
    
    def _parse_response(self, data: Dict) -> Dict:
        """解析 API 响应数据"""
        # API 直接返回数据，不需要从 data.get('data') 中提取
        
        # 提取视频信息
        video_info = {
            'success': True,
            'title': data.get('text', ''),
            'thumbnail': '',
            'duration': data.get('duration', 0),
            'formats': [],
            'subtitles': []
        }
        
        # 解析 medias 数组
        medias = data.get('medias', [])
        for media in medias:
            media_type = media.get('media_type', '')
            
            if media_type == 'video':
                # 提取缩略图
                if media.get('preview_url'):
                    video_info['thumbnail'] = media.get('preview_url')
                
                # 提取视频格式
                formats = media.get('formats', [])
                for fmt in formats:
                    quality = fmt.get('quality', 0)
                    quality_note = fmt.get('quality_note', '')
                    # 判断是否分离
                    is_separate = fmt.get('separate', 0) == 1
                    
                    format_info = {
                        'quality': f"{quality}p" if quality else quality_note,
                        'quality_value': quality,
                        'quality_note': quality_note,
                        'format': fmt.get('video_ext', 'mp4'),
                        'video_url': fmt.get('video_url', ''),
                        'audio_url': fmt.get('audio_url'),
                        'filesize': fmt.get('video_size', 0),
                        # 修复：当 separate=0 时音视频合并（has_audio=True）
                        # 当 separate=1 时音视频分离（has_audio=False）
                        'has_audio': not is_separate,
                        'width': 0,  # API 不提供宽度信息
                        'height': quality,  # 使用 quality 作为高度
                        'separate': is_separate,
                    }
                    video_info['formats'].append(format_info)
                
                # 提取字幕
                subtitles = media.get('subtitles', [])
                for subtitle in subtitles:
                    lang_name = subtitle.get('language_name', '')
                    lang_tag = subtitle.get('language_tag', '')
                    urls = subtitle.get('urls', [])
                    
                    if urls:
                        # 使用第一个 URL（通常是 SRT 格式）
                        video_info['subtitles'].append({
                            'language': lang_tag or lang_name,
                            'language_name': lang_name,
                            'url': urls[0].get('url'),
                            'format': urls[0].get('format', 'srt')
                        })
                        
            elif media_type == 'audio':
                # 音频资源（可能需要与视频合并）
                # 暂时不处理，因为高质量视频需要单独的音频流
                pass
        
        # 按质量排序（从高到低）
        video_info['formats'].sort(
            key=lambda x: int(x.get('height', 0)) if x.get('height') else 0,
            reverse=True
        )
        
        return video_info


def extract_video_id(url: str) -> Optional[str]:
    """从 YouTube URL 中提取视频 ID"""
    import re
    
    patterns = [
        r'(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})',
        r'youtube\.com\/embed\/([a-zA-Z0-9_-]{11})',
        r'youtube\.com\/v\/([a-zA-Z0-9_-]{11})',
    ]
    
    for pattern in patterns:
        match = re.search(pattern, url)
        if match:
            return match.group(1)
    
    # 如果已经是 11 位的视频 ID
    if re.match(r'^[a-zA-Z0-9_-]{11}$', url):
        return url
    
    return None


def build_youtube_url(video_id: str) -> str:
    """根据视频 ID 构建完整的 YouTube URL"""
    return f"https://www.youtube.com/watch?v={video_id}"


if __name__ == '__main__':
    # 测试代码
    logging.basicConfig(level=logging.INFO)
    
    service = IIILabYouTubeService()
    
    # 测试视频
    test_url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    
    try:
        result = service.extract_video_info(test_url)
        logger.info(f"标题: {result['title']}")
        logger.info(f"找到 {len(result['formats'])} 个视频格式")
        for fmt in result['formats'][:5]:  # 只显示前5个
            logger.info(f"  - {fmt['quality']} ({fmt['format']})")
    except Exception as e:
        logger.error(f"测试失败: {e}")

