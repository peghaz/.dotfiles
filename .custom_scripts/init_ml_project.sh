#!/bin/bash

# ? Create directory if not exists
mkdir -p config
mkdir -p utils/config
mkdir -p utils/data
mkdir -p models
mkdir -p scripts/train
mkdir -p scripts/eval
mkdir -p scripts/prod
mkdir -p data
mkdir -p models/lightning
mkdir -p logs

if [ ! -f utils/data/__init__.py ]; then
    touch utils/data/__init__.py
fi
if [ ! -f utils/config/__init__.py ]; then
    touch utils/config/__init__.py
fi
if [ ! -f config/project.yaml ]; then
    touch config/project.yaml
fi
if [ ! -f models/__init__.py ]; then
    touch models/__init__.py
fi
if [ ! -f scripts/train/__init__.py ]; then
    touch scripts/train/__init__.py
fi
if [ ! -f scripts/eval/__init__.py ]; then
    touch scripts/eval/__init__.py
fi
if [ ! -f scripts/prod/__init__.py ]; then
    touch scripts/prod/__init__.py
fi
if [ ! -f scripts/__init__.py ]; then
    touch scripts/__init__.py
fi
if [ ! -f data/.gitkeep ]; then
    touch data/.gitkeep
fi
if [ ! -f init.py ]; then
    touch init.py
fi

# ? Create init.py if it doesn't exist
if [ ! -f init.py ]; then
    touch init.py
fi

# Specify the Python interpreter version
python_ver=""

# Parse named arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --python) python_ver="$2"; shift ;;  # Capture the python argument
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done


# Create directory if specified
if [[ -n "$python_ver" ]]; then
    uv init . --python=$python_ver
    uv venv --python=$python_ver
else
    uv init .
    uv venv 
fi

echo "data/*" >> .gitignore
echo "logs" >> .gitignore

# ? If there exists "hello.py", remove it
if [ -f hello.py ]; then
    rm hello.py
fi

if [ -f main.py ]; then
    rm main.py
fi