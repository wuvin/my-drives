# NU M4 Teleoperation Guide

Summary of steps for teleoperating NU M4.

---

## Hardware Setup

- Plug in Telemetry Radio via USB to laptop prior to QGroundControl (QGC)
- Run QGC (`./QGroundControl-x86_64.AppImage`)
- Turn on teleoperation controller BEFORE NU M4
- Ensure switches and controls on controller are in their default down position
- Verify offline WiFi bars in top-right of teleoperation controller screen
- Turn on NU M4 (Jetson & Pixhawk/CubePilot) via battery connection
- Verify online WiFi bars for Pixhawk/CubePilot connection
- Verify M4 connection also on controller screen for Jetson connection
- Toggle ON servo motor power switch on front-side board
- Connect laptop and Jetson to same network
- SSH into Jetson from laptop (num4@num4.local or @192.168.0.133 or .146, usually)

---

## Jetson Setup

- Go to `m4-autonomy/m4-firmware` directory
- If necesssary, ensure any extra USB devices are set up with udev rules
- Check permissions on Pixhawk/CubePilot dev port (e.g., `ls -l /dev/ttyTHS1`)
- Execute `run_docker.sh` (after editing it as needed) or run Docker separately (see Docker Hints below)

### Udev Rules for USB Setup

See local rules within `setup_scripts`.  Pay attention to symlinks when adding.

### Dev Port

When connecting Pixhawk/CubePilot to Jetson via USB, dev port should be 
`/dev/ttyACM0` or similar.

When connecting via JST/TELEM2 to GPIO, dev port should be `/dev/ttyTHS1`.

Permissions for port should be set to 'rw-' or 6 (e.g., `sudo chmod 666 
/dev/ttyTHS1`) 

### Docker Hints

- Verify Docker daemon is active: `sudo systemctl status docker`
- List running Docker containers: `docker ps`
- List all Docker containers, incl. stopped: `docker ps -a` (note IMAGE)
- View Docker images: `docker images` (note TAG)
- Enter running Docker container: `docker exec -it <id or name> bash

## Docker Image

- Go to `m4_ws/src/m4_base` (initial directory may be `/home/m4_home`)
- If necessary, double-check RC channel configuration
- Confirm `launch/interfaces.launch` configures correct dev port (e.g., 
`/dev/ttyTHS1`) and baud rate (e.g., `57600`) for MAVROS
- Create `tmux` sessions for MAVROS interface and controls, starting with 
MAVROS (`tmux new -s mavros`)

### RC Channel Configuration

`config/rc_channel_config.yaml` maps different modes to specific channel IDs.

Channel IDs can be checked by going to the QGC window, entering Vehicle 
Configuration through the top left menu, and changing to the Radio tab.  The 
channels will be shown in the right-side of the tab, where operating a switch 
on the teleoperation controller will show a response in the corresponding 
channel.

## MAVROS Session

- Source `setup.bash` in `devel` folder (relative to `m4_base`, should be 
`source ../../devel/setup.bash` to access `m4_ws`)
- Launch (`roslaunch m4_base interfaces.launch`)
- Check terminal output for RC channels message detected and other connections
- Detach from `tmux` session (via `CTRL + B -> D`)
- Move onto `tmux` session for controls (`tmux new -s controls`)

## Controls Session

- Source `devel/setup.bash`, noting relative path as needed
- Ensure NU M4 platform is placed carefully and ready for morphing
- Launch (`roslaunch m4_base m4_control.launch`), which MORPHS NU M4 INTO DRIVE

---

## Begin Teleoperation

- When changing between modes (including different drive modes), hold NU M4 by 
handle to avoid damage from current issue where one pair of joint and wheel 
servo motors is experiencing a time difference
- Ensure disarm and defaults on teleoperation controller
- Arm
- Check switches now have corresponding response from robot

### Servo Motor Power Switch

By default, the servo motor power switch should default to off outside of 
operation.  This switch must be toggled ON for motors and wheels to be powered 
during teleoperation.

Note that the servo motor power switch should be OFF to allow motors to freely 
move (e.g., by hand).

### Disarm Mode

By default, the teleoperation controller should have its switch in disarm mode 
and all other relevant switches down (i.e., downward when holding controller 
normally).  Disarm disables any response from toggling switches.

Start teleoperation in this manner, then arm to begin toggling switches.

### Other Teleoperation Advice

- To fly, first change mode into full crouch (i.e., body closest to ground)
- Then arm aerial
- Then toggle channel 7 (all the way down?) to reposition wheels/rotors

Note this counts as mode changing.  If there is still a time-delay issue 
between servo motors, then hold NU M4 up to avoid damage.

---

## End Teleoperation

- Ensure NU M4 is ready for morphing reset
- Arm and put all other switches back to default
- Disarm
- Kill controls `tmux` session via `CTRL + C` and `CTRL + D` while attached
- Toggle off servo motor power using switch in front-side board
- Attach active MAVROS interfaces `tmux` session (`tmux at -t mavros`)
- Kill MAVROS session
- Disconnect NU M4 battery power (to turn off Pixhawk/CubePilot and Jetson)
- Turn off teleoperation controller

---
