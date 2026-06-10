#!/bin/bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="linux-lab-toolkit_${TIMESTAMP}"

echo "=============================="
echo "  Archive & Compress Toolkit"
echo "  Date: $(date)"
echo "=============================="

echo ""
echo "Scripts to archive:"
for script in *.sh; do
    SIZE=$(wc -c < "$script" | tr -d ' ')
    echo "  $script ($SIZE bytes)"
done

echo ""
echo "Creating tar archive..."
tar cf "${ARCHIVE_NAME}.tar" *.sh
echo "  Created: ${ARCHIVE_NAME}.tar ($(wc -c < ${ARCHIVE_NAME}.tar | tr -d ' ') bytes)"

echo ""
echo "Compressing with gzip..."
gzip -k "${ARCHIVE_NAME}.tar"
echo "  Created: ${ARCHIVE_NAME}.tar.gz ($(wc -c < ${ARCHIVE_NAME}.tar.gz | tr -d ' ') bytes)"

echo ""
echo "Compression ratio:"
TAR_SIZE=$(wc -c < "${ARCHIVE_NAME}.tar" | tr -d ' ')
GZ_SIZE=$(wc -c < "${ARCHIVE_NAME}.tar.gz" | tr -d ' ')
SAVED=$(( (TAR_SIZE - GZ_SIZE) * 100 / TAR_SIZE ))
echo "  Saved ${SAVED}% with compression"

echo ""
echo "Archive contents:"
tar tf "${ARCHIVE_NAME}.tar"

echo ""
echo "Cleaning up..."
rm "${ARCHIVE_NAME}.tar" "${ARCHIVE_NAME}.tar.gz"
echo "Archive demo complete."
