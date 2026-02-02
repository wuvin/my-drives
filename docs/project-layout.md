# Project Layout

Though different groups and contributors have separate ways of managing development and research content, a standardized format goes a long way to facilitating collaboration.   Inside the "projects" folder are sub-directories with specific purposes; these should follow a clear template.

---

## Project Structure

Below are the recommended layouts (see "layout" definition in Terminology section).  The suggested behavior in [official Python documentation](https://packaging.python.org/en/latest/discussions/src-layout-vs-flat-layout/) includes "src" and "flat" layouts, whereas the "application", "packaged application", and "library" derive from [uv documentation](https://docs.astral.sh/uv/concepts/projects/init/).

Mind the location of the `hello()`.

### Suggested

**src layout**
```text
    project-name/
    ├── pyproject.toml      # [project], [project.scripts], [build-system]
    ├── README.md
    └── src
        └── project_name/
            ├── __init__.py # can be empty
            └── module.py   # def hello(): print("...")
```
Usually in this case, you expect this "package" to be installed (e.g., via `pip install` or `uv pip install` in the active environment) so it can be imported.

**flat layout**
```text
    project-name/
    ├── pyproject.toml  # [project], [project.scripts], [build-system]
    ├── README.md
    └── project_name/
        ├── __init__.py # can be empty, but does dictate import behavior
        └── module.py   # def hello(): print("...")
```
[build-system] may not be needed here without installation in the active environment; you can just `import project_name` in the root directory.
    
**simple (single module) layout**
```text
    project-name/
    ├── pyproject.toml  # [project], [project.scripts], [build-system]
    ├── README.md
    └── project_name.py # def hello(): print("...")
```
[build-system] may not be needed here.  You can `from project_name import hello`.

### Others (uv)

As a whole, I do not recommend using these layouts for now unless you are using uv.  Don't rule out using uv with the above layouts though; it may be worth at least building familiarity.  Translating between layouts also should not be too hard.

**app layout**
```text
    project-name/
    ├── pyproject.toml  # [project]
    ├── README.md
    └── hello.py        # or main.py
```
Refer to uv documentation.  Builds do not work in this set-up, so this is not installable.  You can execute this with `uv run hello.py` in the root directory.

**packaged app layout**
```text
    project-name/
    ├── pyproject.toml      # [project], [project.scripts], [build-system]
    ├── README.md
    └── src
        └── project_name/
            └── __init__.py # contains hello code
```
Source code is moved into `__init__.py`, and [project.scripts] must contain a command definition that links to the function, e.g., `project_name:hello`.  You can then execute `uv run project-name`.

**lib layout**
```text
    project-name/
    ├── pyproject.toml      # [project], [build-system]
    ├── README.md
    └── src
        └── project_name/
            ├── __init__.py # contains hello code
            └── py.typed
```
This layout is intended to be built and distributed.  The `py.typed` is to indicate the presence of types read from the library.

---

## Terminology

Terms used by researchers and developers tend to be conflated and inconsistent across different sources, but this document tries to establish at least a convention to use within the space in which it resides.  This is while sticking as close as possible to both official and popular Python documentation when possible.
- "Project" is, more generally, the structured collection of content working towards a specific goal and, more specifically, a sub-directory within the "projects" folder.
    - It can be associated with a particular robotics platform at the lab, as well as with a specific sprint or behavior being developed for that platform.
    - Feel free to create a new "project" sub-directory folder for a new or a change in purpose, so long as it uses a consistent "layout".
- "Layout" refers to the concept of a project's directory structure, separate from the actual purpose and contents; this is the definition used in official Python documentation.
- "Module" defines functions and statements, alongside other code-based behaviors, which are often contained within a script (or another module).  In Python, these are typically files ending in `.py`.
- An "import package" is a collection of Python modules (i.e., "submodules"), usually as a directory on the file system, that can be imported for use elsewhere.
    - The "import package" is itself a Python module.
    - For example:
        - Let there be two scripts, `listener.py` and `streamer.py`, that define their own set of functions (e.g., `create_listener()`).
        - Both scripts are inside an `offboard_control` folder, which itself is inside the project's root directory.
        - `listener` and `streamer` are submodules of the `offboard_control` module.
    - It can be imported in the project's root directory, e.g., with `import offboard_control` or `from offboard_control import listener`.
    - A submodule PY file can itself be an "import package" when located in a separate folder with the same name, typically alongside `__init__.py`.
    - For example;
        - Folder `listener/` and files `listener/__init__.py` and `listener/listener.py`
        - Can import with `from listener import create_listener`
        - Note that `__init__.py` can dictate import behavior to include the `create_listener` function; otherwise, `create_listener.py` can be a separate script
    - Naming usually uses underscores instead of hyphens.
- A "distribution package" is the same piece of software collection as "import package" with the addition that it has been made installable by other users and *distributed* to a centralized index such as [PyPI](pipy.org).
    - Package installation is managed by setup script or a similar configuration file (e.g., `setup.py`, `pyproject.toml`, `requirements.txt`, `environment.yml`) alongside a corresponding `src` folder containing Python modules.
    - This is typically the same folder as the project root directory containing a setup file and `src`.
    - See https://packaging.python.org/en/latest/discussions/distribution-package-vs-import-package/ for more details.
    - Naming usually uses hyphens instead of underscores.

Note that "package" is overloaded and often, by itself or without context, ambiguous.

---