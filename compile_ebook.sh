#!/bin/bash
#
# RichDSP Documentation Compiler
# Compiles all repository documentation into ebook (EPUB) and PDF formats
#
# Usage: ./compile_ebook.sh [output_name]
#        Default output name: richdsp_complete
#
# Requirements:
#   - pandoc (https://pandoc.org)
#   - For PDF: pdflatex or xelatex (texlive recommended)
#   - For EPUB: pandoc built-in support
#

set -e

# Configuration
OUTPUT_NAME="${1:-richdsp_complete}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
OUTPUT_DIR="${SCRIPT_DIR}/output"

# Metadata for the ebook
TITLE="RichDSP: The Complete Development Chronicle"
AUTHOR="RichDSP Engineering Team"
DATE=$(date +"%Y-%m-%d")
LANG="en-US"

echo "=============================================="
echo "RichDSP Documentation Compiler"
echo "=============================================="
echo ""

# Check for pandoc
if ! command -v pandoc &> /dev/null; then
    echo "ERROR: pandoc is not installed."
    echo "Install with:"
    echo "  Ubuntu/Debian: sudo apt-get install pandoc"
    echo "  macOS: brew install pandoc"
    echo "  Windows: choco install pandoc"
    exit 1
fi

# Create directories
mkdir -p "${BUILD_DIR}"
mkdir -p "${OUTPUT_DIR}"

echo "Collecting documentation files..."

# Create combined markdown file with proper ordering
COMBINED="${BUILD_DIR}/combined.md"

# Start with title page
cat > "${COMBINED}" << 'FRONTMATTER'
---
title: "RichDSP: The Complete Development Chronicle"
subtitle: "A 24-Month Journey Through High-End Audio Engineering"
author: "RichDSP Engineering Team"
date: "2024"
lang: en-US
toc: true
toc-depth: 2
documentclass: report
geometry: margin=1in
fontsize: 11pt
linestretch: 1.2
---

\newpage

FRONTMATTER

echo "Adding narrative chapters..."

# Add the narrative in order
NARRATIVE_DIR="${SCRIPT_DIR}/docs/narrative"
if [ -d "${NARRATIVE_DIR}" ]; then
    # Add executive summary first
    if [ -f "${NARRATIVE_DIR}/00_EXECUTIVE_SUMMARY.md" ]; then
        echo "  - Executive Summary"
        cat "${NARRATIVE_DIR}/00_EXECUTIVE_SUMMARY.md" >> "${COMBINED}"
        echo -e "\n\n\\newpage\n\n" >> "${COMBINED}"
    fi

    # Add monthly chapters in order
    for i in $(seq -w 1 24); do
        CHAPTER_FILE="${NARRATIVE_DIR}/${i}_MONTH_${i#0}.md"
        # Handle leading zeros
        if [ ! -f "${CHAPTER_FILE}" ]; then
            CHAPTER_FILE="${NARRATIVE_DIR}/0${i#0}_MONTH_${i#0}.md"
        fi
        if [ -f "${CHAPTER_FILE}" ]; then
            echo "  - Month ${i#0}"
            cat "${CHAPTER_FILE}" >> "${COMBINED}"
            echo -e "\n\n\\newpage\n\n" >> "${COMBINED}"
        fi
    done
fi

echo ""
echo "Adding architecture documentation..."

# Add architecture documents
ARCH_DIR="${SCRIPT_DIR}/docs/architecture"
if [ -d "${ARCH_DIR}" ]; then
    echo -e "\n\n# Part II: Technical Architecture\n\n" >> "${COMBINED}"

    for doc in SYSTEM_ARCHITECTURE.md ANDROID_AUDIO_HAL.md ANALOG_SIGNAL_PATH.md CLOCK_ARCHITECTURE.md; do
        if [ -f "${ARCH_DIR}/${doc}" ]; then
            echo "  - ${doc}"
            echo -e "\n\n" >> "${COMBINED}"
            cat "${ARCH_DIR}/${doc}" >> "${COMBINED}"
            echo -e "\n\n\\newpage\n\n" >> "${COMBINED}"
        fi
    done
fi

echo ""
echo "Adding team documentation..."

# Add team documents
TEAM_DIR="${SCRIPT_DIR}/docs/team"
if [ -d "${TEAM_DIR}" ]; then
    echo -e "\n\n# Part III: Team Structure\n\n" >> "${COMBINED}"

    for doc in TEAM_HARDWARE.md TEAM_SOFTWARE.md; do
        if [ -f "${TEAM_DIR}/${doc}" ]; then
            echo "  - ${doc}"
            echo -e "\n\n" >> "${COMBINED}"
            cat "${TEAM_DIR}/${doc}" >> "${COMBINED}"
            echo -e "\n\n\\newpage\n\n" >> "${COMBINED}"
        fi
    done
fi

echo ""
echo "Adding review documentation..."

# Add review documents
REVIEW_DIR="${SCRIPT_DIR}/docs/reviews"
if [ -d "${REVIEW_DIR}" ]; then
    echo -e "\n\n# Part IV: Architecture Reviews\n\n" >> "${COMBINED}"

    for doc in REVIEW_SYSTEMS_ARCHITECTURE.md REVIEW_AUDIO_ENGINEERING.md; do
        if [ -f "${REVIEW_DIR}/${doc}" ]; then
            echo "  - ${doc}"
            echo -e "\n\n" >> "${COMBINED}"
            cat "${REVIEW_DIR}/${doc}" >> "${COMBINED}"
            echo -e "\n\n\\newpage\n\n" >> "${COMBINED}"
        fi
    done
fi

echo ""
echo "=============================================="
echo "Generating output formats..."
echo "=============================================="
echo ""

# Generate EPUB
echo "Creating EPUB..."
pandoc "${COMBINED}" \
    --toc \
    --toc-depth=2 \
    --epub-cover-image="${SCRIPT_DIR}/docs/cover.png" 2>/dev/null || true \
    --metadata title="${TITLE}" \
    --metadata author="${AUTHOR}" \
    --metadata date="${DATE}" \
    --metadata lang="${LANG}" \
    -o "${OUTPUT_DIR}/${OUTPUT_NAME}.epub" \
    2>&1 || {
        # Retry without cover image if it doesn't exist
        pandoc "${COMBINED}" \
            --toc \
            --toc-depth=2 \
            --metadata title="${TITLE}" \
            --metadata author="${AUTHOR}" \
            --metadata date="${DATE}" \
            --metadata lang="${LANG}" \
            -o "${OUTPUT_DIR}/${OUTPUT_NAME}.epub"
    }
echo "  Created: ${OUTPUT_DIR}/${OUTPUT_NAME}.epub"

# Generate PDF
echo "Creating PDF..."
if command -v pdflatex &> /dev/null || command -v xelatex &> /dev/null; then
    pandoc "${COMBINED}" \
        --toc \
        --toc-depth=2 \
        --pdf-engine=pdflatex \
        --metadata title="${TITLE}" \
        --metadata author="${AUTHOR}" \
        --metadata date="${DATE}" \
        -V geometry:margin=1in \
        -V fontsize=11pt \
        -V documentclass=report \
        -o "${OUTPUT_DIR}/${OUTPUT_NAME}.pdf" \
        2>&1 || {
            echo "  WARNING: PDF generation with pdflatex failed."
            echo "  Trying xelatex..."
            pandoc "${COMBINED}" \
                --toc \
                --toc-depth=2 \
                --pdf-engine=xelatex \
                --metadata title="${TITLE}" \
                --metadata author="${AUTHOR}" \
                --metadata date="${DATE}" \
                -V geometry:margin=1in \
                -V fontsize=11pt \
                -V documentclass=report \
                -o "${OUTPUT_DIR}/${OUTPUT_NAME}.pdf" \
                2>&1 || {
                    echo "  WARNING: PDF generation failed."
                    echo "  Install texlive for PDF support:"
                    echo "    Ubuntu/Debian: sudo apt-get install texlive-latex-base texlive-fonts-recommended"
                    echo "    macOS: brew install --cask mactex"
                }
        }
    if [ -f "${OUTPUT_DIR}/${OUTPUT_NAME}.pdf" ]; then
        echo "  Created: ${OUTPUT_DIR}/${OUTPUT_NAME}.pdf"
    fi
else
    echo "  WARNING: LaTeX not installed. Skipping PDF generation."
    echo "  Install texlive for PDF support:"
    echo "    Ubuntu/Debian: sudo apt-get install texlive-latex-base texlive-fonts-recommended"
    echo "    macOS: brew install --cask mactex"
fi

# Generate HTML (single page)
echo "Creating HTML..."
pandoc "${COMBINED}" \
    --toc \
    --toc-depth=2 \
    --standalone \
    --metadata title="${TITLE}" \
    --metadata author="${AUTHOR}" \
    --metadata date="${DATE}" \
    -c https://cdn.jsdelivr.net/npm/water.css@2/out/water.css \
    -o "${OUTPUT_DIR}/${OUTPUT_NAME}.html"
echo "  Created: ${OUTPUT_DIR}/${OUTPUT_NAME}.html"

# Generate plain text
echo "Creating plain text..."
pandoc "${COMBINED}" \
    --to plain \
    --wrap=auto \
    -o "${OUTPUT_DIR}/${OUTPUT_NAME}.txt"
echo "  Created: ${OUTPUT_DIR}/${OUTPUT_NAME}.txt"

# Generate DOCX
echo "Creating DOCX..."
pandoc "${COMBINED}" \
    --toc \
    --toc-depth=2 \
    --metadata title="${TITLE}" \
    --metadata author="${AUTHOR}" \
    --metadata date="${DATE}" \
    -o "${OUTPUT_DIR}/${OUTPUT_NAME}.docx"
echo "  Created: ${OUTPUT_DIR}/${OUTPUT_NAME}.docx"

# Count statistics
echo ""
echo "=============================================="
echo "Compilation Statistics"
echo "=============================================="
WORD_COUNT=$(wc -w < "${COMBINED}")
LINE_COUNT=$(wc -l < "${COMBINED}")
CHAR_COUNT=$(wc -c < "${COMBINED}")
echo "  Total words: ${WORD_COUNT}"
echo "  Total lines: ${LINE_COUNT}"
echo "  Total characters: ${CHAR_COUNT}"
echo ""

# List output files
echo "Output files:"
ls -lh "${OUTPUT_DIR}/${OUTPUT_NAME}"* 2>/dev/null || true
echo ""

# Cleanup option
echo "Build files in: ${BUILD_DIR}"
echo "To clean up: rm -rf ${BUILD_DIR}"
echo ""
echo "Done!"
