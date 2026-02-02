---
File: another-readme.md
Contact: wu.kevi@northeastern.edu
Last Modified: August 20, 2025
---


# S-1TB-KJW3/

Another drive.

| Quick Info | |
| - | - |
| Author | Kevin Wu |
| Email | wu.kevi@northeastern.edu |
| Drive | S-1TB-KJW3 |
| Date | July 08, 2025 |

---

## Directory Structure

```text
dev/
├── bin/          # Standalone scripts and executables (e.g., *.sh, *.exe)
├── config/       # Hidden configuration folders (e.g., .ssh, .git, .conda)
├── projects/     # Project directories, incl. workspaces, packages, libraries
├── datasets/     # General data repository
├── software/     # Software packages or installations
└── README.md     # This documentation file
```

The project directory structure also follows a format.  See `projects/README.md` and `docs/project-layout.md`.

---

## Known Drives

```text
H-1TB-KWU1                 # External HDD
H-300GB-WUKEVI2            # HDD enclosure drive
S-1TB-KJW3
kjw@HOME-UB22              # Home desktop computer
jungle@puget-267523-02     # jungle user account on remote NAIL machine 
kwu@siliconsynapse         # Ubuntu user account on high bay tower
Laptop                     # Low-spec Lenovo ThinkPad used for school
  or DESKTOP-TU98PR9
  or kwu
```

---

## Cross-Platform Compatibility

### Porting environments

Environments typically are not portable across different OSes (e.g., Windows 11, Ubuntu 22.04) because compiled binaries are OS-specific.  For example, Windows uses `.dll` and `.pyd`; Linux uses `.so`.

Instead, rebuild the environment on a different OS using `environment.yml` or `requirements.txt` inside the project.  This requires each project maintaining an up-to-date environment or requirements file for `conda` or `pip` respectively.

### Shell scripting

Helper scripts inside `bin` should:
- Use platform-aware logic (e.g., detect `uname` or `os.name`).
- Avoid absolute path references; instead, rely on commands (e.g., `$PWD`, `$(dirname "$0")`) or relative paths.

---

## Customization

### Shell Initialization

A "run commands" (rc) file can be used to automatically configure the terminal (e.g., activate a Conda environment, change directories, source a ROS setup file).  You can see examples with `~\.bashrc`, which is launched with `CTRL + ALT + T`, and `~/.devrc`.  The latter rc file is used by some non-default profiles for the terminal, including one that activates the base conda environment within `~/dev/miniconda3`.  

### Terminal Profile

A custom profile can be used when opening a new terminal to retain color scheme and custom commands upon initialization (e.g., as in an rc file).

Steps (for GNOME terminal):
1. Open a new terminal (e.g., `CTRL + ALT + T`)
2. Right-click in terminal > Preferences
3. Create a new profile (e.g., "YourName") by clicking the plus sign next to "Profiles" within the left pane
4. Under the "Command" tab, check "Run a custom command instead of my shell" and enter (as an example):

```bash
/bin/bash --rcfile "~/.devrc" -i -c "source ~/dev/miniconda3/bin/activate && bash"
```

To use a profile, either:
- right-click in terminal > `Profiles` > [profile name] (switches current activate profile)
- select down symbol at top left of GNOME terminal and click on desired profile (creates new terminal window with selected profile)

Note that "`... && bash`" is an input command for keeping open the terminal window after applying any defined custom commands.

### VS Code Profile

VS Code also can use profiles similarly to isolate individual settings, extensions, and behavior of both the terminal and code editor built-into the Code app:
See `File` > `Preferences` > `Profile` > `Profiles`.

You can also modify `.vscode/settings.json` for initialization use by VS Code as well.  The following example shows how to source or use a different Python installation:

```json
{
    "terminal.integrated.defaultPath.linux": "YourName Dev",
    "python.defaultInterpreterPath": "./env/bin/python"
}
```

---

## Some Ubuntu Tips

### Keyboard
- `CTRL + ALT + T`: Open a new terminal.  This launches a Bash shell and sources the default `.bashrc` file.
- `CTRL + SHIFT + C/V`: Copy/paste in terminal.  `CMD + C/V` from macOS may be `CTRL + C/V` in Ubuntu.
- `CTRL + L`: Clear screen of selected terminal.
- `CTRL + ALT + Left/Right`: Switch active monitor.  Note that RustDesk will sometimes have another monitor containing any extra space on the remote display; this can be accessed through the `v` button in the RustDesk top sidebar.

Other typical shortcuts (e.g., `ALT + F4`, `ALT + TAB`) should have their expected functionalities.

### Filesystem
- `cd ~`: bash command to go to home directory (i.e., /home/kwu/)
- `vim ~/.bashrc`: bash command to open `.bashrc` file in vim editor.  Avoid making changes to shared files such as `.bashrc` without consulting others.
- ~/.bashrc (i.e., /home/kwu/.bashrc): default initialization file used when launching a Bash shell.
- ~/dev/: directory intended to contain workspaces for code development.
- ~/dev/miniconda3/: conda installation.

Standard commands (e.g., `ls`, `pwd`) in bash terminal are available.

### Vim
- `I`: enter insert mode.
- `ESC`: return to command mode.
- `:w`: save.
- `:q`: quit.
- `:wq`: save and quit.

There are other commands (e.g., `:x`) and mappings (e.g., `SHIFT + Z + Z`) to also check out when convenient.

### Terminal

Verify command path is correct (e.g., system `/usr/local/bin/python` or local `.venv/bin/python`)

```bash
    which python
    which pip
    which conda
```

Adding to path (prepending takes priority; appending does not)

```bash
    PATH="~/dev/software/miniconda3:$PATH"
```

NOTE: Consider `pip` vs. `conda` vs. `uv`

Create virtual environment (pip)

```bash
    python -m venv .venv
```

Activate virtual environment (pip)
```bash
    source .venv/bin/activate
```

Rebuild environment after activation (pip)
```bash
    pip install -r requirements.txt
```

Create and rebuild environment (conda)
```bash
    conda env create -p .conda -f environment.yml
```

Activate virtual environment (conda)
```bash
    conda activate .conda
```
