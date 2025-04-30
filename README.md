# FASTQ Phred Encoding Classifier

This repository contains tools to classify FASTQ files based on their quality score encoding (Phred+33 or Phred+64).

## Background

FASTQ is a text-based format for storing both biological sequence data and its corresponding quality scores. The quality scores are encoded as ASCII characters, but historically two different encodings have been used:

1. **Phred+33 encoding**: ASCII values starting from 33 (e.g., Sanger, Illumina 1.8+)
2. **Phred+64 encoding**: ASCII values starting from 64 (e.g., Illumina 1.3+, Illumina 1.5+)

This encoding difference creates compatibility issues when processing FASTQ files from different sources. This tool helps identify and organize FASTQ files based on their encoding.

## Contents

- `script.sh`: Script to generate random FASTQ files with either Phred+33 or Phred+64 encoding (provided externally)
- `sort_fastq_by_phred.sh`: Script to detect Phred encoding and sort files into appropriate directories

## How It Works

The sorting script (`sort_fastq_by_phred.sh`) uses the following approach to detect Phred encoding:

1. Extract quality score lines from the FASTQ file (every 4th line)
2. Use `od` (octal dump) to convert ASCII characters to their decimal values
3. Find the minimum ASCII value in the quality scores
4. Classify the file:
   - If minimum value < 58, classify as Phred+33
   - Otherwise, classify as Phred+64

This approach is based on the observation that Phred+33 encoding typically uses ASCII values 33-73, while Phred+64 encoding uses ASCII values 64-104.

## Usage

### Step 1: Generate random FASTQ files

```bash
# Download and run the provided script
chmod +x script.sh
./script.sh
```

This will generate 10 random FASTQ files in the current directory with randomly assigned Phred+33 or Phred+64 encoding.

### Step 2: Sort files by Phred encoding

```bash
# Make the script executable
chmod +x sort_fastq_by_phred.sh

# Run the script
./sort_fastq_by_phred.sh
```

The script will:
1. Create `phred33/` and `phred64/` directories
2. Analyze each FASTQ file
3. Move each file to the appropriate directory based on its encoding
4. Display a summary of the classification results

## Implementation Details

### Algorithm for Phred Detection

Our script uses `od` (octal dump) to examine the raw byte values of quality scores in FASTQ files. The approach:

1. **Extract quality scores**: We parse the FASTQ format to extract only the quality score lines (every 4th line)
2. **Convert to numeric values**: The `od -An -t dC -v` command converts ASCII characters to their decimal values
3. **Find minimum value**: By finding the minimum ASCII value in the quality scores, we can determine the encoding offset
4. **Apply threshold**: We use a threshold of 58 to differentiate between Phred+33 and Phred+64 encoding

### Explanation of `od` Command

The `od` command is used with the following options:
- `-An`: Don't print address offsets
- `-t dC`: Display both decimal values (`d`) and character representation (`C`)
- `-v`: Display all input data, even if duplicated

Example output from `od -An -t dC -v` for a quality string:
```
 70  F   71  G   72  H   73  I   74  J   75  K   76  L
```

In this output, each quality character is shown with its decimal ASCII value, making it easy to determine the encoding.

## Limitations

- This method assumes the files are valid FASTQ files
- The detection is based on statistical inference - examining minimum values
- Very short or unusual FASTQ files might be misclassified in rare cases

## Future Improvements

- Add support for other FASTQ variations (e.g., Illumina 1.5+ with B-encoding)
- Implement more robust detection using character frequency distribution
- Add validation of FASTQ format before processing
- Include options for parallel processing of large file sets

## License

This project is licensed under the MIT License - see the LICENSE file for details.
