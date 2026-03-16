<!--
---
File: docs/m4-autonomy-examples.md
Contact: wu.kevi@northeastern.edu
Last Modified: March 16, 2026
---
-->

# m4-autonomy-examples

Some notes walking through hypothetical scenarios of development for
`m4-autonomy` and what steps may be taken for those cases while following the
desired design process.

---

## Examples

### Compressing RealSense images with image_transport

- If dependencies already present, then only need changes inside /opt/m4_ws
    * Tweak config as needed in /opt/m4_ws/src/m4-sensors/realsense2_bringup
    * Also tweak launch as needed in same package
    * Colcon build in m4_ws (e.g., `colcon build --packages-select 
      realsense2_bringup`)
    * Once verified, commit/push m4-sensors
- If not present, then
    * Add, e.g., `ros-humble-image-transport` and 
      `ros-humble-compressed-image-transport` to Dockerfile.realsense
    * Image (re-)build
    * Tweak in m4_ws as above

### Adding Foxglove Bridge

Note that Dockerfiles may already include `ros-humble-foxglove-bridge`, but for
the purposes of this hypothetical, assume that this has not yet been done.
Instead, we are exploring its addition.

- First phase exploratory work/testing
    * Clone ros-foxglove-bridge repository into /opt/m4_ws/src/ 
    * Colcon build in m4_ws (assuming dependencies are OK)
    * Test as needed
- Decide to keep
    * Install in Dockerfile.base (no need for separate package in
      /opt/m4_ws/src/ anymore)
    * Image (re-)build
    * Use as normal (e.g., `ros2 launch foxglove_bridge
      foxglove_bridge_launch.xml`)

### Integrating sensor feedback in control & planning

- Test new code
- Move custom config, launch, (sub-)package into appropriate folder (e.g.,
  m4-sensors, m4-firmware, m4-perception)
- Colcon build in m4_ws
- If new repository (e.g., m4-planning), then add bind mount to run-docker.sh so
  that it shows up as /opt/m4_ws/src/m4-planning 

### Using alternative camera

- Need new SDK/driver so...
- Add new Dockerfile (e.g., Dockerfile.newcam)
- Image (re-)build
- Create new config, launch, (sub-)package as needed (e.g., newcam_bringup in
  m4-sensors)
- Colcon build in m4_ws
- Test
- Commit and push
