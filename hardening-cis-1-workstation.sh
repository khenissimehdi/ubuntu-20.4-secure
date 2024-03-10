#!/bin/bash

LOG_NAME="hardening-cis1-wb-ubunutu-20.04.log"
BEFORE_REPORT_NAME="before-hardening-cis1-wb-ubunutu-20.04.html"
AFTER_REPORT_NAME="after-hardening-cis1-wb-ubunutu-20.04.html"
LOG_DIR="/tmp"
LOG_PATH="$LOG_DIR/$LOG_NAME"
TARGET_DIR="/usr/share/xml/scap/ssg/content"
DOWNLOAD_URL="https://github.com/ComplianceAsCode/content/releases/download/v0.1.69/scap-security-guide-0.1.69.zip"
ZIP_FILE="scap-security-guide-0.1.69.zip"
EXTRACTED_DIR="scap-security-guide-0.1.69"
PROFILE_NAME="ssg-ubuntu2004-ds-1.2.xml"
SUB_PROFILE_NAME="xccdf_org.ssgproject.content_profile_cis_level1_workstation"
HARDERNING="ubuntu2004-script-cis_level1_workstation.sh"

logging() {
    # Logging function
    #
    # Takes in a log level and log string and logs to /Library/Logs/$script_name if a
    # LOG_PATH constant variable is not found. Will set the log level to INFO if the
    # first built-in $1 is passed as an empty string.
    #
    # Args:
    #   $1: Log level. Examples "info", "warning", "debug", "error"
    #   $2: Log statement in string format
    #
    # Examples:
    #   logging "" "Your info log statement here ..."
    #   logging "warning" "Your warning log statement here ..."
    log_level=$(printf "%s" "$1" | /usr/bin/tr '[:lower:]' '[:upper:]')
    log_statement="$2"
    script_name="$(/usr/bin/basename "$0")"
    prefix=$(/bin/date +"[%b %d, %Y %Z %T $log_level]:")

    # see if a LOG_PATH has been set
    if [[ -z "${LOG_PATH}" ]]; then
        LOG_PATH="/tmp${script_name}"
    fi

    if [[ -z $log_level ]]; then
        # If the first builtin is an empty string set it to log level INFO
        log_level="INFO"
    fi

    if [[ -z $log_statement ]]; then
        # The statement was piped to the log function from another command.
        log_statement=""
    fi

    # echo the same log statement to stdout
    /bin/echo "$prefix $log_statement"

    # send log statement to log file
    printf "%s %s\n" "$prefix" "$log_statement" >>"$LOG_PATH"
    printf "%s %s\n" "$prefix" "$log_statement" 
}

exit_on_error() {
   logging "ERROR" "An error occurred on $1. Exiting..."
    exit 1
}


logging "" "Updating package lists ..."
sudo apt update || exit_on_error Updating


logging "" "Upgrading packages ..."
sudo apt upgrade -y || exit_on_error Upgrading


logging "" "Installing libopenscap8 ..."
sudo apt install libopenscap8 || exit_on_error libopenscap8

logging "" "Installing ssg-debderived ..." || exit_on_error ssg-debderived
sudo apt install ssg-base ssg-debderived ssg-debian ssg-nondebian ssg-applications


logging "" "Installing unzip ..." || exit_on_error "unzip"
sudo apt install unzip


# Download the file using wget
logging "" "Downloading SCAP Security Guide from $DOWNLOAD_URL"
sudo wget -P "$TARGET_DIR" "$DOWNLOAD_URL" || exit_on_error "Failed to download the file from $DOWNLOAD_URL"


logging "" "Download complete!"


logging "" "Unzipping $ZIP_FILE"
sudo unzip "$TARGET_DIR/$ZIP_FILE" || exit_on_error "Failed to unzip $ZIP_FILE"

logging "" "Operation complete!"

logging "" "Starting the before Scan !"
sudo oscap xccdf eval --profile "xccdf_org.ssgproject.content_profile_cis_level1_workstation" --report "$LOG_DIR/$BEFORE_REPORT_NAME" "$TARGET_DIR/$EXTRACTED_DIR/$PROFILE_NAME" 


Logging "" "Running the hardeing !" 

sudo bash "$TARGET_DIR/$EXTRACTED_DIR/bash/$HARDERNING" || exit_on_error "Failed the hardening"

logging "" "Starting the after Scan !"
sudo oscap xccdf eval --profile "xccdf_org.ssgproject.content_profile_cis_level1_workstation" --report "$LOG_DIR/$AFTER_REPORT_NAME" "$TARGET_DIR/$EXTRACTED_DIR/$PROFILE_NAME" 


logging "" "Finished the hardning go the /tmp to comapre the before and after !"

exit 0