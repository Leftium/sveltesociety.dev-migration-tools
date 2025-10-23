#!/usr/bin/env bash

set -e

# Get date parameter or default to 7 days ago
if [ -z "$1" ]; then
  CUTOFF_DATE=$(date -v-7d +%Y-%m-%d)
  echo "No date provided, using default: $CUTOFF_DATE (7 days ago)"
else
  CUTOFF_DATE=$1
  echo "Using provided date: $CUTOFF_DATE"
fi

# Validate date format
if ! date -j -f "%Y-%m-%d" "$CUTOFF_DATE" >/dev/null 2>&1; then
  echo "Error: Invalid date format. Please use YYYY-MM-DD"
  exit 1
fi

# Convert to Unix timestamp
CUTOFF_TIMESTAMP=$(date -j -f "%Y-%m-%d" "$CUTOFF_DATE" +%s)
echo "Cutoff timestamp: $CUTOFF_TIMESTAMP"
echo ""

# Find video IDs that need refreshing
echo "Finding videos from $CUTOFF_DATE onwards..."
VIDEO_IDS=$(jq -r --argjson cutoff "$CUTOFF_TIMESTAMP" \
  '.[] | select(.timestamp >= $cutoff or (.release_timestamp // 0) >= $cutoff) | .id' \
  src/lib/data/youtube.json)

VIDEO_COUNT=$(echo "$VIDEO_IDS" | wc -l | xargs)
echo "Found $VIDEO_COUNT videos to refresh"
echo ""

if [ "$VIDEO_COUNT" -eq 0 ]; then
  echo "No videos to refresh"
  exit 0
fi

# Remove from archive to force refetch
echo "Removing videos from archive..."
for VIDEO_ID in $VIDEO_IDS; do
  sed -i '' "/youtube $VIDEO_ID/d" src/lib/data/archive.txt
  echo "  $VIDEO_ID"
done
echo ""

# Remove from JSON so fresh data replaces old
echo "Removing videos from youtube.json..."
VIDEO_IDS_JSON=$(echo "$VIDEO_IDS" | jq -R . | jq -s .)
jq --argjson ids "$VIDEO_IDS_JSON" \
  'map(select(.id as $id | $ids | index($id) | not))' \
  src/lib/data/youtube.json > src/lib/data/youtube-temp.json \
  && mv src/lib/data/youtube-temp.json src/lib/data/youtube.json
echo "Removed from JSON"
echo ""

# Run fetch script
echo "Running fetch-videos.sh to refetch data..."
./scripts/fetch-videos.sh
