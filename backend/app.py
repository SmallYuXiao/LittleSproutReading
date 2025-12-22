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
        
        logger.info(f"Fetching subtitles for video: {video_id}, language: {preferred_lang}")
        
        # 获取字幕列表
        transcript_list = YouTubeTranscriptApi.list_transcripts(video_id)
        
        # 尝试获取指定语言的字幕
        try:
            transcript = transcript_list.find_transcript([preferred_lang])
        except:
            # 如果指定语言不存在,尝试获取英文字幕
            try:
                transcript = transcript_list.find_transcript(['en', 'en-US', 'en-GB'])
            except:
                # 如果英文也不存在,获取第一个可用字幕
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
        
        logger.info(f"Successfully fetched subtitles: {len(subtitle_data)} entries")
        
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
        logger.error(f"Error fetching subtitles: {str(e)}")
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
        logger.info(f"Fetching available languages for video: {video_id}")
        
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
        logger.error(f"Error fetching languages: {str(e)}")
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
        
        logger.info(f"Extracting video URL for: {video_id}, quality: {quality}")
        
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
                        logger.info(f"Selected combined format: {fmt.get('format_id')} - {fmt.get('format_note')}")
                        break
                
                # 第二优先级:如果没有合并格式,尝试找 HLS 流
                if not video_url:
                    for fmt in info['formats']:
                        if (fmt.get('url') and 
                            fmt.get('protocol') == 'm3u8_native' and
                            'storyboard' not in fmt.get('format_id', '')):
                            video_url = fmt['url']
                            logger.info(f"Selected HLS format: {fmt.get('format_id')}")
                            break
                
                # 第三优先级:任何有视频的格式(可能没有音频)
                if not video_url:
                    for fmt in reversed(info['formats']):
                        if (fmt.get('url') and 
                            fmt.get('vcodec') != 'none' and
                            'storyboard' not in fmt.get('format_id', '')):
                            video_url = fmt['url']
                            logger.info(f"Selected video-only format: {fmt.get('format_id')} (WARNING: may not have audio)")
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
            
            logger.info(f"Successfully extracted video URL (length: {len(video_url)})")
            
            return jsonify(video_info)
        
    except Exception as e:
        logger.error(f"Error extracting video URL: {str(e)}")
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
        logger.info(f"Fetching YouTube info via iiilab for: {video_id}")
        
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
        
        logger.info(f"Successfully fetched video info: {result['title']}")
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Error fetching YouTube info: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e),
            'video_id': video_id
        }), 400


if __name__ == '__main__':

    print("=" * 60)
    print("🚀 YouTube 字幕服务已启动")
    print("=" * 60)
    print("📍 服务地址: http://localhost:5001")
    print("📖 API 文档:")
    print("   - 健康检查: GET /health")
    print("   - 获取字幕: GET /api/subtitles/<video_id>?lang=en")
    print("   - 可用语言: GET /api/languages/<video_id>")
    print("   - 获取视频URL: GET /api/video-url/<video_id>")
    print("   - 获取视频信息(iiilab): GET /api/youtube-info/<video_id>")
    print("=" * 60)
    print("💡 示例:")
    print("   curl http://localhost:5001/api/subtitles/dQw4w9WgXcQ")
    print("=" * 60)
    
    app.run(host='0.0.0.0', port=5001, debug=True)
