#!/usr/bin/env bash
# Usage:
#   ./ros2_msg2csv.sh <ros2_msg_type> <csv_file>
# Example:
#   ./ros2_msg2csv.sh sensor_msgs/msg/Imu imu.csv

set -euo pipefail

MSG_TYPE="$1"
CSV_FILE="$2"

PRIMITIVES="bool byte char float32 float64 int8 uint8 int16 uint16 int32 uint32 int64 uint64 string wstring"

is_primitive() {
    local t="$1"
    for p in $PRIMITIVES; do
        [[ "$t" == "$p" ]] && return 0
    done
    return 1
}

normalize_type() {
    local t="$1"
    if is_primitive "$t"; then
        echo "$t"
    else
        if [[ "$t" == */msg/* ]]; then
            echo "$t"
        else
            local pkg="${t%%/*}"
            local name="${t##*/}"
            echo "${pkg}/msg/${name}"
        fi
    fi
}

expand_fields() {
    local type="$1"
    local prefix="$2"

    # Only look at non-indented lines here
    ros2 interface show "$type" | grep -v '^[[:space:]]' | while read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        field_type=$(echo "$line" | awk '{print $1}')
        field_name=$(echo "$line" | awk '{print $2}')

        # detect array size if present
        array_size=""
        if [[ "$field_type" =~ \[([0-9]+)\]$ ]]; then
            array_size="${BASH_REMATCH[1]}"
            field_type="${field_type%\[*\]}"
        fi

        [[ -z "$field_name" ]] && continue

        if is_primitive "$field_type"; then
            if [[ -n "$array_size" ]]; then
                # Expand fixed-size arrays into multiple columns
                for ((i=0; i<array_size; i++)); do
                    echo "${prefix}${field_name}_${i}"
                done
            else
                echo "${prefix}${field_name}"
            fi
        else
            local norm_type
            norm_type=$(normalize_type "$field_type")
            expand_fields "$norm_type" "${prefix}${field_name}_"
        fi
    done
}

header=$(expand_fields "$MSG_TYPE" "" | paste -sd, -)

if [[ ! -f "$CSV_FILE" ]]; then
    echo "$header" > "$CSV_FILE"
else
    first_line=$(head -n 1 "$CSV_FILE")
    if [[ "$first_line" != "$header" ]]; then
        tmpfile=$(mktemp)
        {
            echo "$header"
            cat "$CSV_FILE"
        } > "$tmpfile"
        mv "$tmpfile" "$CSV_FILE"
    fi
fi

echo "CSV header written to $CSV_FILE"
