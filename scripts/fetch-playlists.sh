#!/usr/bin/env bash

set -e

echo "Fetching playlists..."
PLAYLIST_IDS=$(yt-dlp --flat-playlist --print "%(id)s" "https://www.youtube.com/@SvelteSociety/playlists" 2>/dev/null)

TOTAL_PLAYLISTS=$(echo "$PLAYLIST_IDS" | wc -l)
echo "Found $TOTAL_PLAYLISTS playlists"
echo ""

PLAYLISTS_JSON="[]"
PLAYLIST_NUM=0
for PLAYLIST_ID in $PLAYLIST_IDS; do
  PLAYLIST_NUM=$((PLAYLIST_NUM + 1))
  echo "Fetching playlist $PLAYLIST_NUM/$TOTAL_PLAYLISTS: $PLAYLIST_ID"
  
  PLAYLIST_INFO=$(yt-dlp --flat-playlist --print "%(playlist_id)s|%(playlist_title)s|%(playlist_count)s" --playlist-end 1 "https://www.youtube.com/playlist?list=$PLAYLIST_ID" 2>/dev/null | head -1)
  
  IFS='|' read -r PL_ID PL_TITLE PL_COUNT <<< "$PLAYLIST_INFO"
  
  VIDEO_IDS=$(yt-dlp --flat-playlist --print "%(id)s" "https://www.youtube.com/playlist?list=$PLAYLIST_ID" 2>/dev/null | jq -R . | jq -s .)
  
  PLAYLIST_ENTRY=$(jq -n \
    --arg id "$PL_ID" \
    --arg title "$PL_TITLE" \
    --argjson count "$PL_COUNT" \
    --argjson video_ids "$VIDEO_IDS" \
    '{id: $id, title: $title, video_count: $count, video_ids: $video_ids}')
  
  PLAYLISTS_JSON=$(echo "$PLAYLISTS_JSON" | jq --argjson entry "$PLAYLIST_ENTRY" '. + [$entry]')
done

echo "$PLAYLISTS_JSON" | jq . > src/lib/data/playlists.json
echo "Playlists saved: $(echo "$PLAYLISTS_JSON" | jq 'length') playlists"
echo ""
