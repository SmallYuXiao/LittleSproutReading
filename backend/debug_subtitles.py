from youtube_transcript_api import YouTubeTranscriptApi
import sys

video_id = 'dduQeaqmpnI'
try:
    print(f"Listing transcripts for {video_id}...")
    transcript_list = YouTubeTranscriptApi.list_transcripts(video_id)
    for transcript in transcript_list:
        print(f" - {transcript.language_code}: {transcript.language} (generated: {transcript.is_generated})")
except Exception as e:
    print(f"Error: {e}")
