# uv

An extremely fast Python package and project manager, written in Rust.  As a single tool, it can replace `pip`, `pip-tools`, `pipx`, `poetry`, `pyenv`, `virtualenv`, and more.

See [https://docs.astral.sh/uv/guides/projects/](https://docs.astral.sh/uv/guides/projects/) for more info.

---

## Setup and Installation

Follow instructions at [https://github.com/astral-sh/uv](https://github.com/astral-sh/uv).  The remainder of this document highlights important info.

---

## Project Structure

***References***:
- https://docs.astral.sh/uv/guides/projects/#project-structure
- https://docs.astral.sh/uv/concepts/projects/layout/

For a project, uv uses metadata and configuration files to manage a persistent environment.  Below is how a typical root directory of a project would look.
```text
	.
	├── .git/
	├── .venv/
	├── .gitignore
	├── .python-version
	├── main.py
	├── pyproject.toml
	├── README.md
	└── uv.lock
```

The important ones are:
- `.venv/`: This folder contains the project's virtual environment, which is where uv will install dependencies, separately from the rest of your system.  uv looks for `.venv` by default.
- `pyproject.toml`: Project metadata is contained in this human-readable TOML file.  It is a standardized way to specify dependencies, similar to `requirements.txt`, and it can be editted manually or by uv.
- `uv.lock`: This cross-platform "lockfile" contains more exact information to resolve versioning in the project environment

Created by `uv init`:
- .git
- .gitignore
- .python-version
- main.py
- pyproject.toml
- uv.lock

## Virtual Environments

uv can create and manage virtual environments such as `.venv`, but it does not directly manage Conda environments. uv is fundamentally a Python package manager; although it can be integrated into or adapt a Conda environment, it does not manage non-Python dependencies like Conda does.

### TO ADD

- Create
- Activate
- Dependencies
- Temporary

### Conda

uv is fundamentally a Python package manager; although it can be integrated into or adapt a Conda environment, it does not manage non-Python dependencies like Conda does.

It is best practice to stick to Conda for projects that rely on Conda, `environment.yml`, or `environment.yaml`.

## Syncing Locking

## More Helpful Info

### Cheatsheet

**Install uv on OS**
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**Create new project**\
```bash
uv init myproj
```

**Install packages**
```bash
uv add django requests "pandas>=2.3"
```

**Remove package**
```bash
uv remove django
```

**See pkg dependency tree**
```bash
uv tree
```

**Run a python script directly w/o starting venv**
```bash
uv run main.py
```

**Install specific version of python**
```bash
uv python list
uv python install 3.12
```

**Start a new project and pin it to python 3.12**
```bash
uv init myproject
uv python pin 3.12
uv add django
uv run main.py # will automatically install py3.12 and django into venv
```

**Use alias for `uv tool run`**
```bash
uvx
```

**Run a cli tool like ruff**
```bash
uv run tool ruff (or uvx ruff)
```

**Update uv version to latest**
```bash
uv self update
```

**Update dependencies in lock file**
```bash
uv lock --upgrade
```

**??**
```bash
uv pip list --outdated
```

---