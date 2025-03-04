from fastapi import FastAPI
from .routers import login

app = FastAPI()

app.include_router(login.router)

""" 
Check if the backend opened up successfully
"""
@app.get('/')
def root():
    return {'backend status': 'open'}
