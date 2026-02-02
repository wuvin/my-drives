#!/bin/bash

# Script to add headers to ROS 2 CSV files by inspecting message structure
# Usage: ./add_csv_headers.sh <message_type> <csv_file> [backup_suffix]
#
# Examples:
#   ./add_csv_headers.sh sensor_msgs/msg/Imu imu_data.csv
#   ./add_csv_headers.sh geometry_msgs/msg/Twist cmd_vel.csv .bak

set -e  # Exit on any error

# Function to display usage
print_usage() {
    echo "Usage: $0 <message_type> <csv_file> [backup_suffix]"
    echo ""
    echo "Parameters:"
    echo "  message_type   ROS 2 message type (e.g., sensor_msgs/msg/Imu)"
    echo "  csv_file       Path to the CSV file to modify"
    echo "  backup_suffix  Optional backup suffix (default: .bak)"
    echo ""
    echo "Examples:"
    echo "  $0 sensor_msgs/msg/Imu imu_data.csv"
    echo "  $0 geometry_msgs/msg/Twist cmd_vel.csv .backup"
    echo ""
    exit 1
}

# Function to recursively parse message fields
parse_message_fields() {
    local msg_type="$1"
    local prefix="$2"
    local indent="$3"
    
    # Get the message definition
    local msg_def
    if ! msg_def=$(ros2 interface show "$msg_type" 2>/dev/null); then
        echo "Error: Could not get message definition for $msg_type" >&2
        return 1
    fi
    
    # Process each field in the message
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Extract field type and name
        if [[ "$line" =~ ^[[:space:]]*([^[:space:]]+)[[:space:]]+([^[:space:]]+).*$ ]]; then
            local field_type="${BASH_REMATCH[1]}"
            local field_name="${BASH_REMATCH[2]}"
            
            # Handle array notation (remove brackets)
            field_name=$(echo "$field_name" | sed 's/\[.*\]$//')
            
            # Construct full field path
            local full_field_name
            if [[ -n "$prefix" ]]; then
                full_field_name="${prefix}.${field_name}"
            else
                full_field_name="$field_name"
            fi
            
            # Check if this is a primitive type or custom message
            case "$field_type" in
                bool|int8|uint8|int16|uint16|int32|uint32|int64|uint64|float32|float64|string)
                    # Primitive type - add to headers
                    echo "$full_field_name"
                    ;;
                builtin_interfaces/msg/Time|std_msgs/msg/Header)
                    # Special handling for common types
                    if [[ "$field_type" == "builtin_interfaces/msg/Time" ]]; then
                        echo "${full_field_name}.sec"
                        echo "${full_field_name}.nanosec"
                    elif [[ "$field_type" == "std_msgs/msg/Header" ]]; then
                        echo "${full_field_name}.stamp.sec"
                        echo "${full_field_name}.stamp.nanosec"
                        echo "${full_field_name}.frame_id"
                    fi
                    ;;
                geometry_msgs/msg/Vector3)
                    # Common geometry type
                    echo "${full_field_name}.x"
                    echo "${full_field_name}.y"
                    echo "${full_field_name}.z"
                    ;;
                geometry_msgs/msg/Quaternion)
                    # Quaternion type
                    echo "${full_field_name}.x"
                    echo "${full_field_name}.y"
                    echo "${full_field_name}.z"
                    echo "${full_field_name}.w"
                    ;;
                *)
                    # Try to recursively parse custom message types
                    if [[ "$field_type" =~ ^[a-zA-Z0-9_]+/msg/[a-zA-Z0-9_]+$ ]]; then
                        # Recursively parse the custom message type
                        parse_message_fields "$field_type" "$full_field_name" "$((indent + 1))"
                    else
                        # Fallback: treat as primitive
                        echo "$full_field_name"
                    fi
                    ;;
            esac
        fi
    done <<< "$msg_def"
}

# Check arguments
if [[ $# -lt 2 || $# -gt 3 ]]; then
    usage
fi

MESSAGE_TYPE="$1"
CSV_FILE="$2"
BACKUP_SUFFIX="${3:-.bak}"

# Check if ros2 command is available
if ! command -v ros2 >/dev/null 2>&1; then
    source /opt/ros/humble/setup.bash
fi

echo "Analyzing message type: $MESSAGE_TYPE"

# Get the field names by parsing the message structure
FIELD_NAMES=$(parse_message_fields "$MESSAGE_TYPE" "")

if [[ -z "$FIELD_NAMES" ]]; then
    echo "Error: No fields found for message type $MESSAGE_TYPE" >&2
    exit 1
fi

# Convert field names to comma-separated header string
HEADER_STRING=$(echo "$FIELD_NAMES" | tr '\n' ',' | sed 's/,$//')

echo "Generated header: $HEADER_STRING"

# Create new CSV
if [[ ! -f "$CSV_FILE" ]]; then
    echo "$HEADER_STRING" > "$CSV_FILE"
    exit 0
fi

# Add header to the beginning of the file
echo "Adding header to $CSV_FILE"
sed -i "1i $HEADER_STRING" "$CSV_FILE"