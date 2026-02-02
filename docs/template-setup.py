from setuptools import setup, find_packages

def get_requirements(filepath):
    """Reads requirements from a file."""
    with open(filepath, 'r') as f:
        return [line.strip() for line in f if line.strip()
                and not line.startswith('#')]

# Setup configuration
setup(
    name='wutils',
    packages=find_packages(),
    install_requires=get_requirements('requirements.txt'),
    author='wuvin',
    description='A package of shared utility scripts.',
    long_description=open('README.md').read(),
    long_description_content_type='text/markdown'
)