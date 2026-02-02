# Project Title

Simple overview of use/purpose.  Sections are optional, so use as needed.

---

## Directory Structure

```text
dev/
├── bin/          # Standalone scripts and executables (e.g., *.sh, *.exe)
├── config/       # Hidden configuration folders (e.g., .ssh, .git, .conda)
├── projects/     # Project-specific workspaces
│   └── DPVO/     # e.g., Deep Patch Visual Odometry repository
├── datasets/     # Data repository
└── README.md     # This documentation file
```

---

## Description

An in-depth paragraph about your project and overview of use.

---

## Setup and Installation

### Getting started

**Clone the repository**
~~~
git clone https://github.com/wuvin/wutils
~~~

**Install package and dependencies**  
(*Note*: [setup.py](setup.py) is configured to read [requirements.txt](requirements.txt))
~~~
pip install .
~~~

### Executing program

* How to run the program
* Step-by-step bullets
```
code blocks for commands
```

---

## Help

Any advise for common problems or issues.
```
command to run if program contains helper info
```

---

## Authors

Contributors names and contact info

ex. Dominique Pizzie  
ex. [@DomPizzie](https://twitter.com/dompizzie)

## Helpful Links

Inspiration, code snippets, etc.
* [awesome-readme](https://github.com/matiassingers/awesome-readme)
* [PurpleBooth](https://gist.github.com/PurpleBooth/109311bb0361f32d87a2)
* [dbader](https://github.com/dbader/readme-template)
* [zenorocha](https://gist.github.com/zenorocha/4526327)
* [fvcproductions](https://gist.github.com/fvcproductions/1bfc2d4aecb01a834b46)


<!-- Old stuff # Title
Description. Papers:

[Title](url)<br/>
FirstName LastName, FirstName LastName <sub></sub><br/>
[Title](httpurl)<br/>
First Last, FirstLast<br/>

<a target="_blank" href="colab link">
  <img src="https://colab.research.google.com/assets/colab-badge.svg" alt="Open in Colab"/>

[<img src="img url" width="600">](url for click to go somewhere)

~~~
@bibtex
~~~

## Setup and Installation
This repository is structured as a Python package and includes Git submodules for managing dependencies.</br>

This code was tested on OS and SOFTWARE.</br>

Clone the main repository only
~~~
git clone https://github.com/wuvin/REPOSITORY
~~~

Clone the repository with all submodules
~~~
git clone https://github.com/wuvin/REPOSITORY --recursive
~~~

Create and activate the anaconda environment
~~~
cd REPOSITORY
conda env create -f environment.yml
conda activate REPOSITORY
~~~

Install dependencies from requirements file
~~~bash
cd REPOSITORY
pip install -r requirements.txt
~~~

Next install the package
~~~bash
# Install external package
wget https://gitlab.com/libeigen/eigen/-/archive/3.4.0/eigen-3.4.0.zip
unzip eigen-3.4.0.zip -d thirdparty

# Install package
pip install .
~~~

Install package and dependencies (Note: [setup.py](setup.py) is configured to read [requirements.txt](requirements.txt))

### Subsection - Subsection
Note: You will need to have (e.g., CUDA 11 and CuDNN) installed on your system.

1. Step
~~~
code
~~~

2. Step
~~~bash
code
~~~

## Another Section
Description

### Subsection
Description

## Change Log
* **MONTH YEAR**: Description

## Acknowledgements
Description -->