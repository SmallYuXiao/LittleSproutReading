from youtube_transcript_api import YouTubeTranscriptApi
import sys

video_id = 'dduQeaqmpnI'
try:
    transcript_list = YouTubeTranscriptApi.list_transcripts(video_id)
    
    # 获取第一个可用字幕（应该是 auto-generated en）
    transcript = list(transcript_list)[0]
    
    # 尝试翻译
    translated = transcript.translate('zh-Hans')
    data = translated.fetch()
except Exception as e:
