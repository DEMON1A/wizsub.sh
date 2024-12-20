#!/bin/bash

# Check if the 'subwiz' command exists
if ! command -v subwiz &> /dev/null; then
    echo "subwiz not found. Attempting to install it..."

    # Check if pip exists
    if command -v pip &> /dev/null; then
        pip install subwiz
    elif command -v pip3 &> /dev/null; then
        pip3 install subwiz
    else
        echo "Neither pip nor pip3 is installed. Please install Python's pip to proceed."
        exit 1
    fi

    # Verify installation
    if command -v subwiz &> /dev/null; then
        echo "subwiz installed successfully."
    else
        echo "Failed to install subwiz. Please check your Python/pip setup."
        exit 1
    fi
fi

# Ensure the script is run with three arguments
# Only the first 3 arguments are required 
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <domain_name> <number_of_loops> <subdomains_file_path> <number_of_predictions>"
    exit 1
fi

# Construct the variables 
DOMAIN=$1
LOOPS=$2
FILE=$3
NUM=${4:-500}   # assign the value to "500" if $4 is empty

# Check if the input file exists, create it if not
if [ ! -f "$FILE" ]; then
    touch "$FILE"
    # TODO: implement another version of the script that collects subdomains first before 
    # doing the subwiz thing
fi

if [ "$LOOPS" = "x"  ]; then
    # if loops = "x" then don't stop until subwiz doesn't return subdomains anymore
    COUNTER=1
    while true; do
        echo "[Loop $COUNTER] Running subwiz for domain: $DOMAIN"

        # Run the command and get results
        RESULTS=$(subwiz -i "$FILE" -n "$NUM" | grep -i "$DOMAIN" | grep -v '^$')

        # Count the number of subdomans subwiz found
        COUNT=$(echo "$RESULTS" | wc -l)

        # Append results to the file if any new subdomains are found
        if [ -n "$RESULTS" ]; then
            echo "$RESULTS" >> "$FILE"
        else
            echo "[Loop $COUNTER] Subwiz couldn't find any subdomains anymore"
            echo "Adjust the number of predictions and try again if you still wish to enumerate more subdomains"
            exit 1
        fi

        echo "[Loop $COUNTER] Found $COUNT subdomains"

        # Adjust the counter
        ((COUNTER++))
    done
else
    for ((i = 1; i <= LOOPS; i++)); do
        echo "[Loop $i] Running subwiz for domain: $DOMAIN"

        # Run the command and get results
        RESULTS=$(subwiz -i "$FILE" -n "$NUM" | grep -i "$DOMAIN" | grep -v '^$')

        # Count the number of subdomains found
        COUNT=$(echo "$RESULTS" | wc -l)

        echo "[Loop $i] Found $COUNT subdomains"

        # Append results to the file if any new subdomains are found
        if [ -n "$RESULTS" ]; then
            echo "$RESULTS" >> "$FILE"
        else
            echo "[Loop $COUNTER] Subwiz couldn't find any subdomains anymore"
            echo "Adjust the number of predictions and try again if you still wish to enumerate more subdomains"
            exit 1
        fi
    done

    echo "Script completed after $LOOPS loops."
fi
