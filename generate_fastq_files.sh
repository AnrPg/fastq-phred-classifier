#!/bin/bash

# Parameters
NUM_FILES=10    # Number of FASTQ files to generate
NUM_READS=1000  # Number of reads per file
MIN_LENGTH=30  # Minimum read length
MAX_LENGTH=150 # Maximum read length

# Define possible DNA bases
BASES=("A" "T" "G" "C")

# Function to randomly choose Phred+33 or Phred+64
choose_phred_scale() {
    if (( RANDOM % 2 == 0 )); then
        echo "33"
    else
        echo "64"
    fi
}

# Function to generate a random DNA sequence
generate_sequence() {
    local length=$1
    local seq=""
    for ((i=0; i<length; i++)); do
        seq+=${BASES[RANDOM % 4]}
    done
    echo "$seq"
}

# Function to generate a clean quality score string based on Phred encoding
generate_quality() {
    local length=$1
    local phred=$2
    local qual=""

    for ((i=0; i<length; i++)); do
        if [ "$phred" == "33" ]; then
            qual+=$(printf "\\$(printf '%03o' $((RANDOM % 42 + 33)))")  # ASCII 33–74
        else
            qual+=$(printf "\\$(printf '%03o' $((RANDOM % 41 + 64)))")  # ASCII 64–104
        fi
    done
    echo "$qual"
}

# Function to generate a FASTQ header (Illumina-style)
generate_header() {
    local read_num=$1
    local lane=$((RANDOM % 10 + 1))
    local tile=$((RANDOM % 100 + 1))
    local x=$((RANDOM % 2000 + 100))
    local y=$((RANDOM % 2000 + 100))
    local length=$2
    echo "@SRR001666.${read_num} 071112_SLXA-EAS1_s_7:${lane}:${tile}:${x}:${y} length=${length}"
}

# Loop to generate multiple FASTQ files
for ((f=1; f<=NUM_FILES; f++)); do
    OUTPUT_FILE="mock_reads_${f}.fastq"  # Dynamic file name
    PHRED_ENCODING=$(choose_phred_scale)  # Choose random Phred encoding
    > "$OUTPUT_FILE"  # Clear file before writing

    echo "Generating FASTQ file: $OUTPUT_FILE with $NUM_READS reads... (Phred+$PHRED_ENCODING)"

    for ((i=1; i<=NUM_READS; i++)); do
        READ_LENGTH=$((RANDOM % (MAX_LENGTH - MIN_LENGTH + 1) + MIN_LENGTH))  # Random read length

        # Generate FASTQ entry
        header=$(generate_header "$i" "$READ_LENGTH")
        sequence=$(generate_sequence "$READ_LENGTH")
        quality=$(generate_quality "$READ_LENGTH" "$PHRED_ENCODING")

        # Write to file
        echo -e "$header\n$sequence\n+\n$quality" >> "$OUTPUT_FILE"
    done

    # Remove any unwanted Windows-style line endings and hidden characters
    tr -cd '\11\12\15\40-\176' < "$OUTPUT_FILE" > "clean_$OUTPUT_FILE" && mv "clean_$OUTPUT_FILE" "$OUTPUT_FILE"
    sed -i 's/\r$//' "$OUTPUT_FILE"
    echo "Created $OUTPUT_FILE successfully! (Phred+$PHRED_ENCODING)"
done

echo "All FASTQ files generated!"
