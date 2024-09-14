#!/usr/bin/with-contenv bash
# shellcheck shell=bash

prefix="deluge-"
suffix=".dev0"
cmd="git describe --tags --match ${prefix}[0-9]*"

if output=$(eval "$cmd" 2>/dev/null); then
    version="${output#"$prefix"}"
    version="${version%"$suffix"}"
    # Check if there is a dash in the version string
    if [[ "$version" == *"-"* ]]; then
        # Determine the segment type
        segment=".dev"
        if [[ "$version" != *"dev"* ]]; then
            segment=".post"
        fi

        # Process the version string to format it correctly
        version=$(echo "$version" | awk -F'-' -v seg="$segment" '
        {
            # Remove the last group after the final dot
            split($1, parts, ".")
            n = length(parts)
            if (n > 1) {
                $1 = parts[1] "." parts[2] "." parts[3] seg substr($2,1,3)
            }
            print $1
        }')
    fi

    echo "$version"
else
    echo "None"
fi
