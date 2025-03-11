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

## DB Driver

Driver install can be found here (for Linux):
https://learn.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver16&tabs=alpine18-install%2Calpine17-install%2Cdebian8-install%2Credhat7-13-install%2Crhel7-offline

Instructions for setup can be found here:
https://github.com/mkleehammer/pyodbc/wiki/Connecting-to-SQL-Server-from-Linux

Message Nate for connection details (server IP, UID, PWD)
- Server IP will go in odbc.ini
- Make OS environ variables out of UID (call it TF_UID) and
  PWD (call it TF_PWD) for security sake

## Unit Tests

Unit tests should be developed regularly for major parts of the backend.

Run unit tests before pushing code to the remote repo to ensure nothing has broken.

To run all unit tests:
- pytest --import-mode=importlib -v -s
