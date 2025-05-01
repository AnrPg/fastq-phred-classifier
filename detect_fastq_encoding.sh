#!/bin/bash

# detect_fastq_encoding.sh
# This script detects Phred encoding (Phred+33 or Phred+64) in FASTQ files
# and organizes them into appropriate directories.
# 
# Usage: ./detect_fastq_encoding.sh

# Color coding for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

lookup_dir=${1:-"-"} # "-": do autogenerate files {any string, except "-"}: files are already in the specified by this arg directory

echo -e "${BLUE}===== FASTQ File Phred Encoding Detector =====${NC}"
echo "This script identifies Phred+33 vs Phred+64 encoding in FASTQ files"
echo "and sorts them into appropriate directories."
echo ""

# Function to detect encoding for a single FASTQ file
detect_encoding() {
    local file="$1"
    
    echo -e "Analyzing ${GREEN}$file${NC}..."
    
    # Extract quality scores (4th line of each entry)
    # Use od to examine the first few quality lines
    # We'll analyze 10 quality lines to make a robust determination
    
    quality_lines=$(awk '
    NR % 4 == 0 {
        if ($0 ~ /^\+$/) next                # Skip lines that start with newline char
        if ($0 ~ /length/) { next }          # Skip lines that start with "@" and contain "length"
        if ($0 ~ /^[ATCGU]+$/) { next }      # Skip lines that contain only A, T, C, G, U
        if ($0 ~ /^\+$/) { next }            # Skip lines that contain only a "+"
        { print }
    }
    ' "$file" | head -n 100)

    # Use od to convert the quality scores to octal values
    # -An: don't print address
    # -t: specify the format (dC = decimal byte and character)
    # -v: display all input data
    # Use ---> tr -s ' ' '\n'   so that each ascii code is in its own new line (one code per line)
    ascii_values=$(printf "%s\n" "$quality_lines" | od -An -t dC -v | tr -s ' ' '\n' | grep -E '^[0-9]+$')

    # Calculate the minimum ASCII value in the quality scores (grep flushes away some white chars that prev command might have added)
    min_value=$(echo "$ascii_values" | grep -v -E '^(10|32)$' | sort -n | head -n 1)
    
    echo -e "  Minimum ASCII value found: $min_value"
    
    # Determine encoding based on minimum value
    # Phred+33 typically has ASCII values starting from 33
    # Phred+64 typically has ASCII values starting from 64
    if [ "$min_value" -lt 58 ]; then
        echo -e "  Detected: ${GREEN}Phred+33${NC} encoding"
        return 33
    else
        echo -e "  Detected: ${GREEN}Phred+64${NC} encoding"
        return 64
    fi
}

if [ "$lookup_dir" = "-" ]; then
    lookup_dir="$PWD"
    "$PWD/generate_fastq_files.sh"
fi

# Find all FASTQ files in the current directory
IFS=$'\n' read -d '' -r -a fastq_files < <(find "$lookup_dir" -maxdepth 1 -type f -name "*.fastq")

if [ -z "$fastq_files" ]; then
    echo "No FASTQ files found in the current directory."
    exit 1
fi

# Process each FASTQ file
phred33_count=0
phred64_count=0
i=0
for file in "${fastq_files[@]}"; do
    
    original_filepath="$file"
    # Detect encoding and move the file
    detect_encoding "$file"
    encoding=$?
    
    if [ $encoding -eq 33 ]; then
        phred33_count=$((phred33_count+1))
        echo "  Moved to phred33/ directory"
        mv "$original_filepath" "$PWD/phred33/"
    else
        phred64_count=$((phred64_count+1))
        echo "  Moved to phred64/ directory"
        mv "$original_filepath" "$PWD/phred64/"
    fi
done

echo ""
echo -e "===== ${BLUE}Processing Complete${NC} ====="
echo "Found $phred33_count files with Phred+33 encoding"
echo "Found $phred64_count files with Phred+64 encoding"
echo ""
echo "Files have been organized into:"
echo "  - phred33/ directory for Phred+33 encoded files"
echo "  - phred64/ directory for Phred+64 encoded files"

# 3,5,7,9 are Phred33