#!/bin/zsh
# AWS Bedrock cost update and commit script
# Run via crontab: 0 12 * * * /Users/josephchen/Documents/bedrock-costs/update-and-commit.sh

set -e
cd /Users/josephchen/Documents/bedrock-costs

# Source shell profile for AWS credentials
[[ -f ~/.zshrc ]] && source ~/.zshrc 2>/dev/null || true

# Calculate dates
YESTERDAY=$(date -v-1d +%Y-%m-%d)
TODAY=$(date +%Y-%m-%d)

# Query AWS Bedrock cost
COST=$(aws ce get-cost-and-usage \
    --time-period Start=$YESTERDAY,End=$TODAY \
    --granularity DAILY \
    --metrics "UnblendedCost" \
    --filter '{"Dimensions":{"Key":"SERVICE","Values":["Amazon Bedrock"]}}' \
    --query 'ResultsByTime[0].Total.UnblendedCost.Amount' \
    --output text 2>/dev/null || echo "0")

# Skip if cost is 0 or empty
if [[ "$COST" == "0" || -z "$COST" ]]; then
    echo "No Bedrock cost for $YESTERDAY, skipping update"
    exit 0
fi

# Check if date already exists in file
if grep -q "\"$YESTERDAY\"" index.html; then
    echo "Date $YESTERDAY already exists, skipping"
    exit 0
fi

# Add new entry to costData array in index.html
sed -i '' "/\/\/ New entries will be added here/a\\
            { date: \"$YESTERDAY\", cost: \"$COST\" },
" index.html

# Update last updated timestamp
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Commit and push
git add index.html
git commit -m "Update: $YESTERDAY cost \$$COST"
git push origin main

echo "Updated $YESTERDAY: \$$COST"
