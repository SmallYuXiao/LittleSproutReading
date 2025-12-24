from youtube_transcript_api import YouTubeTranscriptApi
import sys

video_id = 'dduQeaqmpnI'
try:
    transcript_list = YouTubeTranscriptApi.list_transcripts(video_id)
    for transcript in transcript_list:
except Exception as e:
