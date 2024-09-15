#!/bin/bash
# needs bash 4.0 or higher to run because associative arrays are used here
input_file="diff.txt"
output_file="release-note.txt"

# associative arrays
declare -A deleted_packages
declare -A added_packages

# Initialize variables
processing_started=false

# Empty the output file if it exists
> "$output_file"

# Read through the diff file line by line
while IFS= read -r line; do
    # Skip lines until the section starting with '@@' is found
    if [[ $line == @@* ]]; then
        processing_started=true
        continue
    fi

    # Only process lines after the '@@' line
    if [[ $processing_started == true ]]; then
        # Skip lines that do not start with '-' or '+'
        if [[ $line != -* && $line != +* ]]; then
            continue
        fi

        # Remove the leading '-' or '+' from the line
        trimmed_line="${line:1}"

        # Extract package name and version from the line
        package_name=$(echo "$trimmed_line" | awk '{print $1}')
        package_version=$(echo "$trimmed_line" | awk '{print $2}')

        if [[ $line == -* ]]; then
            # Store deleted package
            deleted_packages["$package_name"]="$package_version"
        
        elif [[ $line == +* ]]; then
            # Store added package
            added_packages["$package_name"]="$package_version"
        fi
    fi
done < "$input_file"

# Compare deleted and added packages
for package_name in "${!added_packages[@]}"; do
    added_version="${added_packages[$package_name]}"
    deleted_version="${deleted_packages[$package_name]}"

    if [[ -n $deleted_version ]]; then
        echo "Changed: $package_name $deleted_version -> $added_version" >> "$output_file"
        unset deleted_packages["$package_name"]  # Remove from deleted list after handling
    else
        echo "Added: $package_name $added_version" >> "$output_file"
    fi
done

# Check for packages that were deleted but not re-added
for package_name in "${!deleted_packages[@]}"; do
    deleted_version="${deleted_packages[$package_name]}"
    echo "Deleted: $package_name $deleted_version" >> "$output_file"
done
