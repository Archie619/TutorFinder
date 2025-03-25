from fastapi import FastAPI
from .routers import login, classes, profile, class_posts, post

app = FastAPI()

app.include_router(login.router)
app.include_router(profile.router)
app.include_router(classes.router)
app.include_router(class_posts.router)
app.include_router(post.router)

''' 
Check if the backend opened up successfully
'''
@app.get('/')
def root():
    return {'backend status': 'open'}
