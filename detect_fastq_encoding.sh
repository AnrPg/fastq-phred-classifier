#!/bin/bash

# sort_fastq_by_phred.sh
# This script detects Phred encoding (Phred+33 or Phred+64) in FASTQ files
# and organizes them into appropriate directories.
# 
# Usage: ./sort_fastq_by_phred.sh

# Set up output directories
mkdir -p phred33 phred64

# Color coding for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===== FASTQ File Phred Encoding Detector =====${NC}"
echo "This script identifies Phred+33 vs Phred+64 encoding in FASTQ files"
echo "and sorts them into appropriate directories."
echo ""

# Function to detect encoding for a single FASTQ file
detect_encoding() {
    local file=$1
    
    echo -e "Analyzing ${GREEN}$file${NC}..."
    
    # Extract quality scores (4th line of each entry)
    # Use od to examine the first few quality lines
    # We'll analyze 10 quality lines to make a robust determination
    
    quality_lines=$(awk 'NR%4==0' "$file" | head -n 10)
    
    # Use od to convert the quality scores to octal values
    # -An: don't print address
    # -t: specify the format (dC = decimal byte and character)
    # -v: display all input data
    octal_dump=$(echo "$quality_lines" | od -An -t dC -v)
    
    # Calculate the minimum ASCII value in the quality scores
    min_value=$(echo "$octal_dump" | grep -v "^ *$" | tr -s ' ' | cut -d' ' -f1 | sort -n | head -n 1)
    
    echo "  Minimum ASCII value found: $min_value"
    
    # Determine encoding based on minimum value
    # Phred+33 typically has ASCII values starting from 33
    # Phred+64 typically has ASCII values starting from 64
    if [ "$min_value" -lt 58 ]; then
        echo -e "  Detected: ${GREEN}Phred+33${NC} encoding"
        mv "$file" phred33/
        echo "  Moved to phred33/ directory"
        return 33
    else
        echo -e "  Detected: ${GREEN}Phred+64${NC} encoding"
        mv "$file" phred64/
        echo "  Moved to phred64/ directory"
        return 64
    fi
}

# Find all FASTQ files in the current directory
fastq_files=$(find . -maxdepth 1 -name "*.fastq" -type f)

if [ -z "$fastq_files" ]; then
    echo "No FASTQ files found in the current directory."
    exit 1
fi

# Process each FASTQ file
phred33_count=0
phred64_count=0

for file in $fastq_files; do
    # Skip files in subdirectories
    if [[ "$file" == *"/"* && "$file" != "./"* ]]; then
        continue
    fi
    
    # Clean up file path if it starts with ./
    file=${file#./}
    
    # Detect encoding and move the file
    detect_encoding "$file"
    encoding=$?
    
    if [ $encoding -eq 33 ]; then
        phred33_count=$((phred33_count+1))
    else
        phred64_count=$((phred64_count+1))
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