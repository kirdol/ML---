# Making sure that the necessary libraries are installed
import subprocess

# List of packages to install
packages = ['pandas', 'tensorflow', 'scikit-learn', 'matplotlib']

# Loop through the packages and install each one using pip
for package in packages:
    subprocess.run(['pip3', 'install', package], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
