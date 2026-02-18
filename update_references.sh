#!/bin/bash

# Configuration
BASE_PATH="/prototipe-TEST-medicus-adaptative"
PATTERNS=("/assets" "/(tabs)" "/_expo")
DRY_RUN=false

# Check for --dry-run flag
for arg in "$@"; do
    if [ "$arg" == "--dry-run" ]; then
        DRY_RUN=true
        echo "--- DRY RUN MODE ENABLED ---"
    fi
done

echo "Updating static references to include prefix: ${BASE_PATH}"

# Function to perform replacement
update_file() {
    local file=$1
    local changed=false
    local content=$(cat "$file")
    
    for pattern in "${PATTERNS[@]}"; do
        # Escape parenthesis for sed if necessary, but here we use it as a literal string check
        # We use a negative lookbehind-like check by ensuring we don't match if already prefixed
        # Since sed doesn't support lookbehinds easily, we match the prefix optionally and replace
        
        # Pattern to match: /assets etc NOT preceded by BASE_PATH
        # Simple approach: replace BASE_PATH/pattern with pattern first to normalize, 
        # then replace /pattern with BASE_PATH/pattern
        
        if [[ $content == *"$pattern"* ]]; then
            echo "  Found match in: $file"
            if [ "$DRY_RUN" = true ]; then
                echo "    [Dry Run] Would update references to ${pattern}"
            else
                # Using | as separator for sed to avoid conflict with / in paths
                # 1. Normalize: remove existing prefix if any
                sed -i "s|${BASE_PATH}${pattern}|${pattern}|g" "$file"
                # 2. Apply: add prefix
                sed -i "s|${pattern}|${BASE_PATH}${pattern}|g" "$file"
                changed=true
            fi
        fi
    done
    
    if [ "$changed" = true ]; then
        echo "  Updated: $file"
    fi
}

# Find files and process them
# Excluding .git and the script itself
find . -type f \( -name "*.html" -o -name "*.js" -o -name "*.json" -o -name "*.css" \) ! -path "*/.git/*" ! -name "update_references.sh" | while read -r file; do
    update_file "$file"
done

echo "Done."
