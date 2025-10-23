#!/usr/bin/env bash

set -e

echo "Fetching playlist info..."
TOTAL=$(yt-dlp --flat-playlist --print "%(id)s" "https://www.youtube.com/@SvelteSociety/" 2>/dev/null | wc -l)
echo "Total videos in playlist: $TOTAL"
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
  
  LAST_ARCHIVED=$(wc -l < src/lib/data/archive.txt 2>/dev/null || echo 0)
  
  yt-dlp \
    --skip-download \
    --ignore-errors \
    --download-archive src/lib/data/archive.txt \
    --sleep-interval 3 --max-sleep-interval 10 \
    --sleep-requests 1 \
    --max-downloads 5 \
    --print '{"id": "%(id)s", "description": %(description)j, "duration": %(duration)s, "width": %(width)s, "height": %(height)s, "timestamp": %(timestamp)s, "release_timestamp": "%(release_timestamp)s", "title": %(title)j, "subtitles_raw": %(subtitles|{})j, "automatic_captions_raw": %(automatic_captions|{})j}' \
    --force-write-archive \
    "https://www.youtube.com/@SvelteSociety/" \
    | tee >(jq -r '.id' >&2) \
    | jq '.release_timestamp = (if .release_timestamp == "NA" then null else (.release_timestamp | tonumber) end) | .subtitles = (.subtitles_raw != {}) | .automatic_captions = (.automatic_captions_raw != {}) | del(.subtitles_raw, .automatic_captions_raw)' \
    | jq -s --slurpfile old src/lib/data/youtube.json '($old[0] // []) + . | unique_by(.id) | sort_by(.timestamp)' \
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
  
  if [ "$ARCHIVED" -eq "$LAST_ARCHIVED" ]; then
    echo ""
    echo "No progress made - likely live/scheduled videos remaining"
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
