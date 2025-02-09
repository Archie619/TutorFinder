# The Backend

This folder contains files and logic for the TutorFinder backend

## Version

Currently, the backend is being developed in Python 3.11.11

## Basics

To get the backend up and running perform the following...

1. Make / open your python venv
    - If not created: python -m venv .venv
    - If activating: source .venv/bin/activate

2. Install the requirements.txt if not installed:
    - pip install -r requirements.txt
    - NOTE: requirements in backend folder

3. Start uvicorn:
    - uvicorn api_init:app --reload

4. The backend is now running!