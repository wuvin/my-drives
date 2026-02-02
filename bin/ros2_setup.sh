#!/bin/bash

# Source system installation
source /opt/ros/humble/setup.bash

if [ $? -eq 0 ]; then
    echo "Sourced /opt/ros/humble/setup.bash"
else
    echo "Failed to source /opt/ros/humble/setup.bash.  Trying /opt/ros/humble/install/setup.bash..."
    source /opt/ros/humble/install/setup.bash
fi

if [ $? -eq 1 ]; then
    echo "Failed to source system ROS 2 installation"
    exit 1
fi

# Source local installation
if [ -d "install/" ]; then
    source install/setup.bash
    if [ $? -eq 0 ]; then
        echo "Sourced $(basename $(dirname ${PWD}))/install/setup.bash"
    else
        echo "Failed to source $(basename $(dirname ${PWD}))/install/setup.bash"
    fi
fi

# Export ROS 2 configuration
export ROS_DOMAIN_ID=42
export RMW_IMPLEMENTATION=rmw_fastrtps_cpp
echo "ROS_DOMAIN_ID set to: ${ROS_DOMAIN_ID}"
echo "RMW_IMPLEMENTATION set to: ${RMW_IMPLEMENTATION}"
