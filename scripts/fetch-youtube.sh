#!/usr/bin/env bash

set -e

echo "Fetching playlist info..."
TOTAL=$(yt-dlp --flat-playlist --print "%(id)s" "https://www.youtube.com/@SvelteSociety/" 2>/dev/null | wc -l)
echo "Total videos in playlist: $TOTAL"
echo ""

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

echo "Starting download loop..."
BATCH_NUM=0
ERROR_COUNT=0
MAX_ERRORS=3

ARCHIVED=$(wc -l < src/lib/data/archive.txt 2>/dev/null || echo 0)
if [ "$ARCHIVED" -ge "$TOTAL" ]; then
  echo "All videos already downloaded!"
  exit 0
fi

while true; do
  BATCH_NUM=$((BATCH_NUM + 1))
  echo "=== Batch $BATCH_NUM ==="
  
  yt-dlp \
    --skip-download \
    --download-archive src/lib/data/archive.txt \
    --sleep-interval 3 --max-sleep-interval 10 \
    --sleep-requests 1 \
    --max-downloads 5 \
    --print '{"id": "%(id)s", "description": %(description)j, "duration": %(duration)s, "width": %(width)s, "height": %(height)s, "timestamp": %(timestamp)s, "title": %(title)j}' \
    --force-write-archive \
    "https://www.youtube.com/@SvelteSociety/" \
    | jq -s 'map(. + {ratio: (.width / .height)})' \
    | jq -s --slurpfile old src/lib/data/youtube.json '[($old[0] // []), .[0]] | add | unique_by(.id) | sort_by(.timestamp)' \
    > src/lib/data/youtube-new.json \
    && mv src/lib/data/youtube-new.json src/lib/data/youtube.json
  
  EXIT_CODE=$?
  
  if [ $EXIT_CODE -ne 0 ]; then
    ERROR_COUNT=$((ERROR_COUNT + 1))
    echo "Error occurred (count: $ERROR_COUNT/$MAX_ERRORS)"
    
    if [ $ERROR_COUNT -ge $MAX_ERRORS ]; then
      echo ""
      echo "Stopping after $MAX_ERRORS consecutive errors (likely rate limited)"
      break
    fi
    
    echo "Continuing..."
    echo ""
    continue
  fi
  
  ERROR_COUNT=0
  
  ARCHIVED=$(wc -l < src/lib/data/archive.txt 2>/dev/null || echo 0)
  REMAINING=$((TOTAL - ARCHIVED))
  PERCENT=$((ARCHIVED * 100 / TOTAL))
  
  echo "Progress: $ARCHIVED/$TOTAL ($PERCENT%) - $REMAINING remaining"
  
  if [ "$ARCHIVED" -ge "$TOTAL" ]; then
    echo ""
    echo "All videos downloaded!"
    break
  fi
  
  echo ""
done

ARCHIVED=$(wc -l < src/lib/data/archive.txt 2>/dev/null || echo 0)
REMAINING=$((TOTAL - ARCHIVED))

echo ""
echo "=== Summary ==="
echo "Total videos: $TOTAL"
echo "Archived: $ARCHIVED"
echo "Remaining: $REMAINING"
