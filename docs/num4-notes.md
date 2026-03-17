# NU M4 Teleoperation Quick Startup

Minimal steps for teleoperating NU M4.

---

## Setup

### Hardware

- NUM4 is off
- Telemetry Radio via USB to Client
- Run QGC on client (`./QGroundControl-x86_64.AppImage`)
- Teleop controller on
    - Check offline WiFi bars (top-right)
- Turn on NUM4
    - Check online WiFi bars
    - Check M4 on screen
- Servo motor power on
- Client SSH into Remote

### Jetson

- Remote 1: `cd m4-autonomy/m4-firmware`
- Remote 1: `./run_docker.sh`

### Docker Image

- Remote 1: `cd m4_ws/src/m4_base`
- Remote 1: `tmux new -s mavros`
- Remote 1: `source ../../devel/setup.bash`
- Remote 1: `roslaunch m4_base interfaces.launch`
- Detach (`CTRL + B -> release -> D`) or new terminal (Remote 2)
- Remote 2: `tmux new -s controls`
- Remote 2: `source ../../devel/setup.bash`
- Ensure NU M4 platform is placed carefully and ready for morphing
- Remote 2: `roslaunch m4_base m4_control.launch` !!MORPHS NU M4 INTO DRIVE!!

---

## Teleoperation

| | ID | DESC | RC |
| - | - | - | - |
| L1 | Arm | Disarm/Arm/Aerial | 12 |
| R1 | Stance | Stand/Crouch/Prone | 11 |
| RS | Drive | ^v Forward/Backward, <> Turn | 1, 2 |
| | Aerial | L1(2) + R1(3) + L1(3) then Drive/Transform | 7 |

---

## Notes

`tmux at -t mavros` to re-attach detached session.

-----

foxglove:
source /opt/ros/humble/setup.bash \
&& ros2 launch foxglove_bridge foxglove_bridge_launch.xml

(Foxglove client > open connection > ws:\\num4.local)

camera:
cd m4_ws/src/m4-sensors \
&& source /opt/ros/humble/setup.bash \
&& source install/setup.bash \
&& export CYCLONEDDS_URI=/home/num4/wuvin/cyclonedds2.xml \
&& ros2 launch realsense2_bringup d435i.launch.py  FAILED (see below)

or ros2 run realsense2_camera realsense2_camera_node

lidar:
cd m4_ws/src/ws_livox \
&& source /opt/ros/humble/setup.bash \
&& source install/setup.bash \
&& export CYCLONEDDS_URI=/home/num4/wuvin/cyclonedds2.xml \
&& ros2 launch livox_ros_driver2 rviz_MID360_launch.py

-----

REALSENSE CAMERA NO LONGER DETECTED AFTER SUDO APT UPGRADE so don't do it
also use new versions now when committing docker image in case it breaks

-----

(terminal 1)
ros2 bag record -s mcap -o run20250829_imu /camera/camera/accel/sample /camera/camera/accel/imu_info /camera/camera/accel/metadata /camera/camera/gyro/sample /camera/camera/gyro/imu_info /camera/camera/gyro/metadata /livox/imu

(terminal 2)
ros2 bag record -s mcap -o run20250829_dpt /camera/camera/depth/image_rect_raw /camera/camera/depth/camera_info

(terminal 3)
ros2 bag record -s mcap -o run20250829_rgb /camera/camera/color/image_raw /camera/camera/color/camera_info

(terminal 4)
ros2 bag record -s mcap -o run20250829_lid /livox/lidar

-----

### ROS 1 Noetic Controls

MAVROS
- source m4_ws/devel/setup.bash
- roslaunch m4_base interfaces.launch

Controls (RC)
- source m4_ws/devel/setup.bash
- roslaunch m4_base m4_control.launch

Controls (Profile)
- source m4_ws/devel/setup.bash
- roslaunch m4_base profile.launch profile:=circle xvel:=0.6 yvel:=0.2 duration:=14 count:=10

-----

### Kamalnath ROS 2 Sensors (`new_docker_test`)

RealSense
- source m4_ws/src/m4-sensors/install/setup.bash
- ros2 launch realsense2_bringup d435i_with_madgwick.launch.py

Livox
- source m4_ws/src/ws_livox/install/setup.bash
- ros2 launch livox_ros_driver2 msg_MID360_launch.py

FAST-LIVO2
- source m4_ws/src/fs_livo2_ws/install/setup.bash
- ros2 launch fast_livo mapping_mid360.launch.py config_file:=mid360.yaml

Recordings
- ros2 bag record -s sqlite3 -o run20260312_hb_mix_out /aft_mapped_to_init /cloud_registered /mavros/vision_pose/pose /rs_imu/data
- ros2 bag record -s sqlite3 -o run20260312_hb_mix_cam /camera/camera/color/camera_info /camera/camera/color/image_raw /camera/camera/color/metadata /camera/camera/aligned_depth_to_color/camera_info /camera/camera/aligned_depth_to_color/image_raw

---
