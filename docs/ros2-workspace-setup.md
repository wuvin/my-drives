# ROS 2 Workspace Setup

This document describes the working layout used inside this development space, particularly for ROS 2 Humble projects.  There are two major approaches covered here: ROS 2 using the system interpreter (e.g., for `colcon`, `python3`), and ROS 2 using a Python virtual environment.  The former is the preferred approach by the community because it leaves dependencies and pathing up to ROS 2 instead of virtualenv, though it does mean project-specific packages and dependencies will be installed system-wide.

---

## Important Preliminary Notes

### ROS 2 Prefers System Interpreter

For example, when using `colcon build` in ROS 2, the build process defaults to the Python interpreter `colcon` was installed with.  This is typically the system's Python interpreter, unless an environment with a different `colcon` is active. 

Activating the virtual environment does not change the preferred interpreter so long as the active `colcon` is still the system version; `colcon build` still adds shebangs referencing the system interpreter at the top of Python nodes or scripts found in the libraries under the "install" folder.  The workaround for this is to set up the environment with its own version of `colcon`, which is shown later in this document.

Use `python3` over `python` in general when using Python with ROS 2.  Double-check that the version is consistent with that of the system interpreter; this should be Python 3.10.12 for ROS 2 Humble on Ubuntu 22.04.

### Be Careful with Virtual Environment

It is still possible to set up a ROS 2 workspace with its own Python environment separate from global.  After activating the virtual environment, check that `which python3` points to the local interpreter and use `pip` and `colcon` as modules of that `python3`.  You can install execute `pip` and `colcon` so long as `which pip` and `which colcon` point to the virtual environment, but to be sure, use `python3 -m pip install ...` and `python3 -m colcon build ...` instead.

Using `colcon` in the manner above does require `colcon-core` and `colcon-common-extensions` to be installed; one of the first commands to execute, after activating the environment, for setting up the virtual environment is `python3 -m pip install empy==3.3.4 colcon-core colcon-common-extensions`.  EmPy 3.3.4 is required to be installed first and is the version that corresponds to ROS 2 Humble.  Sometimes, `lark` should also be installed.

The typical init order for a ROS 2 workspace using a virtual environment is:
1) `source /opt/ros/humble/setup.bash`
2) `source .venv/bin/activate`
3) `source install/setup.bash`

Obviously, steps 2 and 3 should be executed in the workspace directory, where ".venv" and "install" would be located.

### Purpose of Virtual Environment

The main advantage offered with a virtual environment is isolation from the system installation.  ROS 2 development across multiple projects relying on system packages risks version conflict and dependencies issues; for example, two separate projects may require different versions of PyTorch.

With a virtual environment, it is possible to keep dependencies project-specific without modifying the system libraries.

In the context of ROS 2 development, the user must ensure this environment is active during both build and execution if there are packages with dependencies.

### Consider Docker

For isolation of the entire development environment -- OS, Python, ROS 2, dependencies, etc. -- consider using Docker to package development into a container.  This is built into an image.

You do need to re-download software once per image, but code can be mounted into the container, thereby facilitating persistent edits, and images can be shared to enforce the presence of environment dependencies.  This approach is intended for better reproducibility, isolation, and control over the development environment.

It is functionally a portable mini-VM.  This may be overkill for most troubleshooting and code development, but for testing deployment, it is useful.

---

## ROS 2 Directory Structure

Below are the recommended directory layouts for a ROS 2 workspace.  See more in `project-layout.md`.

### Using System Interpreter

```text
    ros2_ws/
    ├── build/ 		# after build process
    ├── install/ 	# after build process
    ├── log/ 		# after build process
    └── src
    	├── ros2_python_package/
    	|   ├── ros2_python_package/
    	|   |   ├── __init__.py
    	|   |   └── package_scripts.py 		# see flat layout modules in `project-layout.md`
    	|   ├── resource/
    	|   |   └── ros2_python_package		# from default package template
    	|   ├── test/
    	|   |   ├── test_copyright.py		# from default package template
    	|   |   ├── test_flake8.py 		# from default package template
    	|   |   └── test_pep257.py		# from default package template
    	|   ├── package.xml
    	|   ├── setup.cfg
        |   └── setup.py
    	├── ros2_cpp_package/
  	|   ├── include/
  	|   |   └── ros2_cpp_package/ 		# from default package template
  	|   ├── src/ 				# optional? from default package template
  	|   ├── CMakeLists.txt
        |   └── package.xml
        └── other_ros2_package/
```

To create either of the template packages for Python, execute in the "src" directory:

```
ros2 pkg create --build-type ament_python <package_name>
```

This can also be done for C++ by changing `ament_python` to `ament_cmake`.

The ROS 2 packages wtihin "src" are usually the contents of the git repository for a package.  These packages may include additional READMEs and licensing.

Python packages should be converted into ROS 2 convention and placed within "src".  This is typically done by first creating a template package directory via `ros2 pkg create` and copying over the package files.  Modifications for `package.xml`, `setup.cfg`, and `setup.py` -- as well as to naming convention -- should be performed as needed.  A similar approach holds for other packages as well.

ROS 2 naming convention appears to be lower-case with underscores.

### Using Virtual Environment

```text
    ros2_ws/
    ├── .venv/ 		# from `python3 -m venv .venv`
    ├── build/ 		# after build process
    ├── install/ 	# after build process
    ├── log/ 		# after build process
    ├── python-package/ # outside of "src"
    └── src
    	├── ros2_python_package/
    	├── ros2_cpp_package/
        └── other_ros2_package/
```

Using a virtual environment forgoes allowing ROS 2 to handle pathing and dependencies; that is, the aim here is to use dependencies installed within a local environment as opposed to the global environment.

This allows "python-package", which is required by another package, to be moved outside of "src" and avoid conversion into a ROS 2 package.

---

## Setup Steps

Below are the suggested steps to creating and using a ROS 2 workspace.

### Using System Interpreter

This follows default ROS 2 usage, as suggested by the community.  Typical steps are:

1) `source /opt/ros/humble/setup.bash`
2) Make workspace directory (e.g., `mkdir -p ros2_ws/src`)
3) Move packages into "src"
4) `colcon build --symlink-install`

`colcon build` can also be executed using the `--base-paths` and `--packages-select` options, especially when it is desired to avoid copying or moving a package from elsewhere into "src".

For further use, first perform these initial steps:
1) Open a new terminal (must be separate from terminal with build process)
2) `source /opt/ros/humble/setup.bash`
3) Go to workspace directory and `source install/setup.bash` in workspace directory

### Using Virtual Environment

These steps include the use of a virtual environment that has its own installation of `colcon`.

1) `source /opt/ros/humble/setup.bash`
2) Make workspace directory (e.g., `mkdir -p ros2_ws/src`)
3) Move desired packages into "src"
4) Move other required packages into workspace directory (i.e., at same level of "src" folder)
5) Create virtual environment (e.g., `python3 -m venv .venv`)
6) Activate virtual environment (i.e., `source .venv/bin/activate)
7) `python3 -m pip install empy==3.3.4 colcon-core colcon-common-extensions jinja2 typeguard` (last two resolve warning message about dependencies)
8) Install packages outside of "src" (i.e., `cd` and `python3 -m pip install -e .`)
9) Install other dependencies (e.g., `python3 -m pip install lark numpy`)
10) `python3 -m colcon build --symlink-install` (in workspace directory)

Step 7 can be fused with Step 9 by just installing everything at once: `python3 -m pip install empy==3.3.4 colcon-core colcon-common-extensions jinja2 typeguard numpy lark`.

For further use, first perform these initial steps:
1) Open a new terminal in workspace directory
2) `source /opt/ros/humble/setup.bash`
3) `source .venv/bin/activate` (in workspace directory)
4) `source install/setup.bash` (in workspace directory)

---
