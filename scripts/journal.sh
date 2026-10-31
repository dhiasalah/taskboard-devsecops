#!/bin/bash
# journal.sh — adds a new lesson entry to JOURNEY.md
# Run it from the project folder: ./scripts/journal.sh

JOURNAL="JOURNEY.md"
TODAY=$(date +%Y-%m-%d)

if [ ! -f "$JOURNAL" ]; then
  echo "❌ $JOURNAL not found. Run me from the project folder."
  exit 1
fi

read -p "Lesson (number — title): " TITLE
read -p "What did you learn? " LEARNED
read -p "What broke? " BROKE
read -p "How did you fix it? " FIXED

echo "" >> "$JOURNAL"
echo "## Lesson $TITLE ($TODAY)" >> "$JOURNAL"
echo "- Learned: $LEARNED" >> "$JOURNAL"
echo "- Broke: $BROKE" >> "$JOURNAL"
echo "- Fixed: $FIXED" >> "$JOURNAL"

echo "✅ Added to $JOURNAL:"
tail -n 5 "$JOURNAL"
