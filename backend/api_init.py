from fastapi import FastAPI
from .routers import login, profile

app = FastAPI()

app.include_router(login.router)
app.include_router(profile.router)

""" 
Check if the backend opened up successfully
"""
@app.get('/')
def root():
    return {'backend status': 'open'}
