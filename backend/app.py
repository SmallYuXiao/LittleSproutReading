#!/usr/bin/env python3
"""
YouTube 字幕服务 API
提供 YouTube 视频字幕获取功能
"""

from flask import Flask, jsonify, request
from flask_cors import CORS
from youtube_transcript_api import YouTubeTranscriptApi
from youtube_transcript_api.formatters import SRTFormatter
import logging
from youtube_iiilab import IIILabYouTubeService, extract_video_id, build_youtube_url

app = Flask(__name__)
CORS(app)  # 允许跨域请求

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 初始化 iiilab YouTube 服务
iiilab_service = IIILabYouTubeService()


@app.route('/health', methods=['GET'])
def health_check():
    """健康检查接口"""
    return jsonify({
        'status': 'ok',
        'service': 'YouTube Subtitle Service',
        'version': '1.0.0'
    })


@app.route('/api/subtitles/<video_id>', methods=['GET'])
def get_subtitles(video_id):
    """
    获取 YouTube 视频字幕
    
    参数:
        video_id: YouTube 视频 ID
        lang: 语言代码(可选,默认: en)
    
    返回:
        JSON 格式的字幕数据
    """
    try:
        # 获取语言参数(默认英文)
        preferred_lang = request.args.get('lang', 'en')
        
        # 获取字幕列表
        transcript_list = YouTubeTranscriptApi.list_transcripts(video_id)
        
        # 扩展语言匹配逻辑
        zh_variants = ['zh-Hans', 'zh-Hant', 'zh', 'zh-CN', 'zh-TW', 'zh-HK', 'zh-SG']
        en_variants = ['en', 'en-US', 'en-GB']
        
        # 尝试获取指定语言的字幕
        try:
            # 如果是中文, 尝试所有变体
            lang_to_search = zh_variants if preferred_lang.startswith('zh') else [preferred_lang]
            transcript = transcript_list.find_transcript(lang_to_search)
        except:
            # 如果指定语言不存在, 尝试翻译
            try:
                # 优先找英文进行翻译
                try:
                    source_transcript = transcript_list.find_transcript(en_variants)
                except:
                    # 没英文就找第一个可用的
                    source_transcript = list(transcript_list)[0]
                
                transcript = source_transcript.translate(preferred_lang)
            except Exception as te:
                # 如果翻译失败, 回退到获取第一个可用字幕
                available_transcripts = list(transcript_list)
                if not available_transcripts:
                    raise Exception("No subtitles available for this video")
                transcript = available_transcripts[0]
        
        # 获取字幕数据
        subtitle_data = transcript.fetch()
        
        # 格式化为 SRT
        formatter = SRTFormatter()
        srt_formatted = formatter.format_transcript(subtitle_data)
        
        # 获取可用语言列表
        available_languages = [
            {
                'code': t.language_code,
                'name': t.language,
                'is_generated': t.is_generated,
                'is_translatable': t.is_translatable
            }
            for t in transcript_list
        ]
        
        
        return jsonify({
            'success': True,
            'video_id': video_id,
            'language': transcript.language_code,
            'language_name': transcript.language,
            'is_generated': transcript.is_generated,
            'subtitle_srt': srt_formatted,
            'subtitle_count': len(subtitle_data),
            'available_languages': available_languages
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e),
            'video_id': video_id
        }), 400


@app.route('/api/languages/<video_id>', methods=['GET'])
def get_available_languages(video_id):
    """
    获取视频可用的字幕语言列表
    
    参数:
        video_id: YouTube 视频 ID
    
    返回:
        可用语言列表
    """
    try:
        
        transcript_list = YouTubeTranscriptApi.list_transcripts(video_id)
        
        languages = [
            {
                'code': t.language_code,
                'name': t.language,
                'is_generated': t.is_generated,
                'is_translatable': t.is_translatable
            }
            for t in transcript_list
        ]
        
        return jsonify({
            'success': True,
            'video_id': video_id,
            'languages': languages
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e),
            'video_id': video_id
        }), 400


@app.route('/api/video-url/<video_id>', methods=['GET'])
def get_video_url(video_id):
    """
    获取 YouTube 视频的直接播放 URL
    
    ⚠️ 警告: 此功能违反 YouTube 服务条款,仅供学习使用
    
    参数:
        video_id: YouTube 视频 ID
        quality: 视频质量(可选,默认: 720p)
    
    返回:
        视频播放 URL
    """
    try:
        import yt_dlp
        
        quality = request.args.get('quality', '720p')
        
        
        ydl_opts = {
            'quiet': True,
            'no_warnings': True,
        }
        
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(f"https://www.youtube.com/watch?v={video_id}", download=False)
            
            # 获取视频 URL
            video_url = None
            
            # 优先从 formats 中选择合适的格式
            if 'formats' in info and info['formats']:
                # 第一优先级:寻找包含视频和音频的格式
                for fmt in reversed(info['formats']):
                    if (fmt.get('url') and 
                        fmt.get('vcodec') != 'none' and 
                        fmt.get('acodec') != 'none' and
                        'storyboard' not in fmt.get('format_id', '')):
                        video_url = fmt['url']
                        break
                
                # 第二优先级:如果没有合并格式,尝试找 HLS 流
                if not video_url:
                    for fmt in info['formats']:
                        if (fmt.get('url') and 
                            fmt.get('protocol') == 'm3u8_native' and
                            'storyboard' not in fmt.get('format_id', '')):
                            video_url = fmt['url']
                            break
                
                # 第三优先级:任何有视频的格式(可能没有音频)
                if not video_url:
                    for fmt in reversed(info['formats']):
                        if (fmt.get('url') and 
                            fmt.get('vcodec') != 'none' and
                            'storyboard' not in fmt.get('format_id', '')):
                            video_url = fmt['url']
                            break
            
            # 备用方案:使用 info 中的 url
            if not video_url and 'url' in info:
                video_url = info['url']
            
            if not video_url or 'storyboard' in video_url:
                raise Exception("无法提取有效的视频 URL")
            
            # 获取视频信息
            video_info = {
                'success': True,
                'video_id': video_id,
                'title': info.get('title'),
                'duration': info.get('duration'),
                'video_url': video_url,
                'thumbnail': info.get('thumbnail'),
                'description': info.get('description', '')[:200]
            }
            
            
            return jsonify(video_info)
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e),
            'video_id': video_id
        }), 400


@app.route('/api/youtube-info/<path:video_id>', methods=['GET'])
def get_youtube_info(video_id):
    """
    使用 iiilab 服务获取 YouTube 视频信息
    
    参数:
        video_id: YouTube 视频 ID 或完整 URL
    
    返回:
        包含视频信息、多种清晰度的播放地址和字幕信息
    """
    try:
        
        # 构建完整的 YouTube URL
        if 'youtube.com' in video_id or 'youtu.be' in video_id:
            youtube_url = video_id
            extracted_id = extract_video_id(video_id)
        else:
            youtube_url = build_youtube_url(video_id)
            extracted_id = video_id
        
        if not extracted_id:
            raise Exception("无效的 YouTube 视频 ID 或 URL")
        
        # 调用 iiilab 服务
        result = iiilab_service.extract_video_info(youtube_url)
        
        
        return jsonify(result)
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e),
            'video_id': video_id
        }), 400


@app.route('/api/video-timestamps/<video_id>', methods=['GET', 'POST'])
def get_video_timestamps(video_id):
    """
    获取 YouTube 视频的带时间戳字幕
    兼容 youtube-api-server 的 API 格式
    
    参数:
        video_id: YouTube 视频 ID (从URL路径获取)
        languages: 语言代码列表(可选,从请求体获取,默认: ["en"])
    
    返回:
        带时间戳的字幕数据
    """
    try:
        # 支持 GET 和 POST 请求
        if request.method == 'POST':
            data = request.get_json() or {}
            languages = data.get('languages', ['en'])
        else:
            lang_param = request.args.get('languages', 'en')
            languages = [lang_param] if isinstance(lang_param, str) else lang_param
        
        logger.info(f"获取视频 {video_id} 的时间戳字幕,语言: {languages}")
        
        # 获取字幕列表
        transcript_list = YouTubeTranscriptApi.list_transcripts(video_id)
        
        # 尝试按优先级获取字幕
        transcript = None
        used_language = None
        
        for lang in languages:
            try:
                # 扩展语言变体
                if lang.startswith('zh'):
                    lang_variants = ['zh-Hans', 'zh-Hant', 'zh', 'zh-CN', 'zh-TW']
                elif lang.startswith('en'):
                    lang_variants = ['en', 'en-US', 'en-GB']
                else:
                    lang_variants = [lang]
                
                transcript = transcript_list.find_transcript(lang_variants)
                used_language = transcript.language_code
                logger.info(f"找到字幕语言: {used_language}")
                break
            except:
                continue
        
        # 如果没找到,尝试翻译
        if not transcript:
            try:
                # 找第一个可用的字幕进行翻译
                available_transcripts = list(transcript_list)
                if available_transcripts:
                    source_transcript = available_transcripts[0]
                    target_lang = languages[0]
                    transcript = source_transcript.translate(target_lang)
                    used_language = target_lang
                    logger.info(f"使用翻译字幕: {source_transcript.language_code} -> {target_lang}")
            except Exception as te:
                logger.error(f"翻译失败: {te}")
        
        # 如果还是没有,使用第一个可用的
        if not transcript:
            available_transcripts = list(transcript_list)
            if not available_transcripts:
                raise Exception("该视频没有可用的字幕")
            transcript = available_transcripts[0]
            used_language = transcript.language_code
            logger.info(f"使用第一个可用字幕: {used_language}")
        
        # 获取字幕数据
        subtitle_data = transcript.fetch()
        
        # 转换为时间戳格式
        timestamps = [
            {
                'text': item['text'],
                'start': item['start'],
                'duration': item['duration']
            }
            for item in subtitle_data
        ]
        
        logger.info(f"成功获取 {len(timestamps)} 条字幕")
        
        return jsonify({
            'success': True,
            'video_id': video_id,
            'language': used_language,
            'timestamps': timestamps,
            'count': len(timestamps)
        })
        
    except Exception as e:
        logger.error(f"获取时间戳字幕失败: {e}")
        return jsonify({
            'success': False,
            'error': str(e),
            'video_id': video_id
        }), 400


if __name__ == '__main__':
    import os
    
    # 从环境变量获取端口,默认 5001
    port = int(os.getenv('PORT', 5001))
    
    
    # 生产环境使用 gunicorn,开发环境使用 Flask 内置服务器
    is_production = os.getenv('RENDER', False)
    app.run(host='0.0.0.0', port=port, debug=not is_production)

