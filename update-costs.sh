#!/bin/bash
set -e

cd "$(dirname "$0")"

# Calculate dates (yesterday and today)
if [[ "$OSTYPE" == "darwin"* ]]; then
    YESTERDAY=$(date -v-1d +%Y-%m-%d)
    TODAY=$(date +%Y-%m-%d)
else
    YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)
    TODAY=$(date +%Y-%m-%d)
fi

# Query AWS Bedrock cost for yesterday
COST=$(aws ce get-cost-and-usage \
    --time-period Start=$YESTERDAY,End=$TODAY \
    --granularity DAILY \
    --metrics "UnblendedCost" \
    --filter '{"Dimensions":{"Key":"SERVICE","Values":["Amazon Bedrock"]}}' \
    --query 'ResultsByTime[0].Total.UnblendedCost.Amount' \
    --output text 2>/dev/null || echo "0")

# Output for use by update script
echo "DATE=$YESTERDAY"
echo "COST=$COST"
