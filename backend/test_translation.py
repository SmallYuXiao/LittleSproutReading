from youtube_transcript_api import YouTubeTranscriptApi
import sys

video_id = 'dduQeaqmpnI'
try:
    print(f"Testing translation for {video_id}...")
    transcript_list = YouTubeTranscriptApi.list_transcripts(video_id)
    
    # 获取第一个可用字幕（应该是 auto-generated en）
    transcript = list(transcript_list)[0]
    print(f"Original: {transcript.language_code} ({transcript.language}), generated: {transcript.is_generated}")
    
    # 尝试翻译
    translated = transcript.translate('zh-Hans')
    data = translated.fetch()
    print(f"Success! Translated {len(data)} entries.")
    print(f"First entry: {data[0]}")
except Exception as e:
    print(f"Error: {e}")
