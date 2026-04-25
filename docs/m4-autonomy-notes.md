<!--
---
File: docs/m4-autonomy-notes.md
Contact: wu.kevi@northeastern.edu
Last Modified: March 17, 2026
---
-->

# m4-autonomy-notes

Some notes and thoughts written down for m4-autonomy design philosophy.
Includes some examples of development process for hypothetical scenarios
taken from `m4-autonomy-examples.md` towards end of this doc.

---

## Design Philosophy

### Bottom line up front

Move points here as needed.

- Docker image = stable build
  * Single source to start from
  * Dockerfiles for system dependencies, drivers, external packages
- Git as "official" record of changes
  * Any local changes desired to be kept MUST be tracked in git
  * Must be proactive to avoid leaving such changes in container
- Persistent but disposable containers for exploratory work
  * Student can keep their container running for convenience (no rebuild)
  * Can nuke at anytime to revert 
  * Must be proactive about using individual container (w/ run-docker.sh)
- Incremental colcon build on only what changed
  * `--symlink-install`
  * `--packages-select`
- Localized edits that are not noted and exist solely in container are
  treated effectively as nonexistent

### Wants/Requirements

- Reproducibility in single comprehensive Docker image...
  * ... absent stale artifacts from previous version(s)
  * ... bypassing errors or issues in present exploratory work
- Stable apt elements via apt-get install in Dockerfiles
- Stable non-apt, external build elements (e.g., RealSense drivers, SDK)
  in `/opt/`
- Custom configs, code as select repositories, packages in `/opt/m4_ws`
  (e.g., /opt/m4_ws/src/m4-sensors/realsense2_bringup/config/param.yaml)
- Temporary or exploratory work also in m4_ws (e.g.,
  /opt/m4_ws/src/test_package)
- Clean separation of temporary localized edits
  * Use of `--rm` intended for changes kept solely in container to not
    persist (e.g., between students checking different things)
  * Possible to `colcon build` on entrypoint to assure fresh, consistent
    build, but risks redundancy if elements are not meaningfully changed
- (Ideally) avoid rebuilding when unnecessary
  * Running container that relaunches same nodes (repeatedly), with same
    functional components => nothing different from previous build
  * Nothing needs to be rebuilt (e.g., repeat run container, add new
    config file or modified param value in existing config YAML) => then
    don't rebuild
  * But if rebuild is needed (e.g., new node in bringup package, new
    package), then do rebuild
- Reproducibility of individual student changes + tracking of
  intermediate steps required to enact such changes
  * Intermediate steps such as apt install of dependencies
  * This was previous problem with multiple workspaces (e.g., Kamalnath's
    new_docker_test) that made both replication and merge inaccessible
  * Problem with multiple containers running (but only if not proactively
    tracked?)

### Build Breakdown

**System `apt` packages**: inside Dockerfile via apt-get install (should we have a
running list of what is installed + where or in which Dockerfile? may
help ensure no redundancies between dependent layers)

**immutable**: inside Docker image, changed only via Dockerfile rebuild
| `/opt/` | desc |
| :-----: | :--- |
| `./ros/humble/` | ROS 2 base, dustynv |
| `./realsense_ws/` | realsense-ros, cv_bridge, librealsense |
| `./livox_ws/` | livox_ros_driver2, Livox-SDK2 |
| `./fastlivo_ws/` | FAST-LIVO2, Sophus, vikit |
| `./px4_ws/` | px4_msgs, MAVSDK |

NOTE: dustynv installs from source

NOTE: check `/opt/ros/humble/...` vs. `/opt/ros/humble/install/...` due
to source installation

**mutable**: bind-mounted from host + tracked in git
| `/opt/m4_ws/src/` | desc |
| :---------------: | :--- |
| `./m4-sensors/` | sensor bringup + configs |
| `./m4-perception/` | SLAM bringup, composed launches |
| `./m4-firmware/` | flight control, mavros interface, servo drivers |

**ephemral**: to be generated inside container; non-persistent (but
between what?)
| `/opt/m4_ws/` | desc |
| :-----------: | :--- |
| `./build` | colcon build output |
| `./install` | colcon install output |
| `./log` | colcon logs |

Ideally these are:
- localized or not shared between versions
- if not bind-mounted, then container-specific

**other**
| dir | desc |
| :-: | :--- |
| `/opt/Livox-SDK2` | needs to be removed; `rm -rf` Dockerfile issue? |

### Entrypoint

Normal command to attach: `docker exec -it <container> bash`; additional
script via `-e` flag

Instead of bare `bash` entrypoint, may need script with conditional exec

Notes on desired functionalities:
- first container creation (i.e., automatic build when install/ is miss)
- subsequent starts of same container (install/ present => no rebuild)
- force rebuild as needed (e.g., `docker exec -e -FORCEFLAG ... bash`)
- what about after meaningful code change? needs rebuild -> leave manual,
  user must `colcon build`

#### Example code

Either as part of `run-docker.sh`, `m4-docker/run_docker.sh`, `.bashrc`,
or otherwise baked into Docker image, e.g.:
```bash
#!/bin/bash
# /opt/m4_entrypoint.sh - desc?
```

Source necessary setup and workspaces
```bash
#source /opt/ros/humble/setup.bash
source /opt/ros/humble/install/setup.bash # NOTE DUSTYNV PATH
source /opt/realsense_ws/install/local_setup.bash
source /opt/livox_ws/install/local_setup.bash
source /opt/fastlivo_ws/install/local_setup.bash
source /opt/px4_ws/install/local_setup.bash
```

Check if RMW is already set
```bash
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
```

Conditional exec of colcon build
```bash
cd /opt/m4_ws
if [ ! -d "install" ]; then  # container's first build
    echo "Running first build for new container..."
    colcon build --symlink-install
elif [ "${FORCE_REBUILD:-0}" = "1" ]; then  # forced build
    echo "Forcing rebuild in existing container..."
    colcon build --symlink-install
fi

if [ -f "/opt/m4_ws/install/local_setup.bash" ]; then
    source /opt/m4_ws/install/local_setup.bash
fi
```

---

## Notes on `--symlink-install`

**Summary**: symlinks in `install/` pointing to `src/`
- No need to rebuild for config file changes (YAML, JSON, launch params),
  as changes go live immediately
- Python launch file changes also immediate
- New Python nodes, so long as rebuild or Python to compile is not
  needed, take effect immediately
- Instances where rebuild is needed:
  * C++ code changes
  * Additional packages

Use `colcon build --packages-select <PACKAGE>` if changes are not
config-only.

---

## Notes on Container Lifecycle

For persistent containers across sessions

### Avoid Rebuild

- Build artifacts stay intact across sessions if container allowed to be
  persistent
- No rebuilding when reattaching to running container

### Possible `run-docker.sh` behavior

- Container is named (and no `--rm`)
- If runnning => attach
- If stopped => start + attach
- Else => create new container

### When to Destroy and Recreate:

- After Docker image is rebuilt (i.e., release of new stable version)
- Switching to different variant (e.g., git branch)
- At discretion of user (e.g., revert to clean slate)

```bash
docker rm -f num4_ros2_humble
```

Then to create fresh container with entrypoint running build
```bash
./run-docker.sh
```

---

## Notes on Possible DOCKER_DEPS.txt

Same idea as `requirements.txt`, `setup.py`, `setup.cfg`, `packages.xml`,
etc. during development of ROS 2 and Python packages.

Each package within `/opt/m4_ws/src/` includes a `DOCKER_DEPS.txt` to
list system dependencies **beyond what is in image**.

Active responsibilities:
- During development, track what is used with `apt-get install`
- During integration, note what is recorded in file as necessary steps to
  rebuild Docker image, and add to associated Dockerfile

### Possible Example File

e.g., `m4-sensors/newcam_bringup/DOCKER_DEPS.txt`:
```txt
# Dependencies to add as Dockerfile.newcam (or to existing Dockerfile)
ros-humble-image-transport
ros-humble-compressed-image-transport
some-more-apt-packages
```

### Possible Workflow

```txt
# Initialization or start
./run-docker.sh  # container creation with 1st build

# Tests + iterations

# Re-building when needed (e.g., with changes to CHANGED_PACKAGE)
colcon build --packages-select <CHANGED_PACKAGE>

# New session or day, or returning to stopped container
./run-docker.sh  # reattach; no rebuild needed, pick up where left off

# Re-build with changed C++ code
colcon build --packages-select <PACKAGE_WITH_C++_CODE>

# Remove old container
docker rm -f num4_ros2_humble

# New image update/rebuild
docker rm -f num4_ros2_humble  # remove
./run-docker.sh                # create

# Revert (e.g., clean slate after something went wrong)
docker rm -f num4_ros2_humble
cd m4-sensors && git checkout main && cd ..  # diff variant, git branch
./run-docker.sh
```

---

## Hypothetical Scenarios

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
