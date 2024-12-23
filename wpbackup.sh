#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "
    Downloading database to public_html"

# Path to wp-config.php
WP_CONFIG="wp-config.php"

# Check if wp-config.php exists
if [[ ! -f $WP_CONFIG ]]; then
    echo "Error: wp-config.php not found in the current directory."
    exit 1
fi

# Extract database credentials from wp-config.php
DB_NAME=$(grep "DB_NAME" $WP_CONFIG | awk -F\' '{print $4}')
DB_USER=$(grep "DB_USER" $WP_CONFIG | awk -F\' '{print $4}')
DB_PASSWORD=$(grep "DB_PASSWORD" $WP_CONFIG | awk -F\' '{print $4}')
DB_HOST=$(grep "DB_HOST" $WP_CONFIG | awk -F\' '{print $4}')

# Check if all credentials were found
if [[ -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASSWORD" || -z "$DB_HOST" ]]; then
    echo "Error: Unable to extract database credentials from wp-config.php."
    exit 1
fi

# Define backup file name with timestamp
BACKUP_FILE="dbdump-$(date +%Y%m%d%H%M%S).sql"

# Perform the database dump
mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$BACKUP_FILE"

# Check if mysqldump was successful
if [[ $? -eq 0 ]]; then
    echo "    Database backup successful: $BACKUP_FILE"
else
    echo "Error: Database backup failed."
    exit 1
fi

# Print the current directory and backup file name
CURRENT_DIR=$(pwd)
echo "    DB dump file located at: $CURRENT_DIR/$BACKUP_FILE"

# ----------------------- New Section: Zipping the Current Directory -----------------------

# Define variables for zipping
TIMESTAMP=$(date +%Y%m%d%H%M%S)
ZIP_FILE="public_html_backup-$TIMESTAMP.zip"
PARENT_DIR=".."
DIR_NAME=$(basename "$CURRENT_DIR")

# Navigate to the parent directory
echo "Navigating to the parent directory: $PARENT_DIR"
cd "$PARENT_DIR"

# Perform the zipping operation
echo "Zipping the current directory ($DIR_NAME) into $ZIP_FILE..."
zip -r "$ZIP_FILE" "$DIR_NAME"

# Check if zip was successful
if [[ $? -eq 0 ]]; then
    echo "    Successfully zipped $DIR_NAME to $PARENT_DIR/$ZIP_FILE"
else
    echo "Error: Failed to zip $DIR_NAME."
    exit 1
fi

# Navigate back to the original directory (optional)
cd "$CURRENT_DIR"

# ----------------------- End of Zipping Section -----------------------

# Remove the script itself
echo "Removing the script: $0"
rm -- "$0"

# Confirm removal
if [[ ! -f "$0" ]]; then
    echo "    Script successfully deleted."
else
    echo "Error: Failed to delete the script."
    exit 1
fi

# Print the final status
echo "    All operations completed successfully."
