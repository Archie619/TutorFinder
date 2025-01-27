from fastapi import FastAPI

app = FastAPI()

""" 
Check if the backend opened up successfully
"""
@app.get("/")
def root():
    return {"Opened successfully?": "Yes!"}

"""
A test of loading posts 

Test yourself using the following command:
curl -X GET http://127.0.0.1:8000/posts
"""
@app.get("/posts")
async def get_posts():
    # This is straight JSON, when we actually get
    # working this will be a pydantic model instead
    return {"posts": 
                {"Post1":
                    {"Exercise": "Running",
                     "Avg Mile Split": "6:32",
                     "Total Miles": 10},
                 "Post2":
                    {"Exercise": "Bench",
                     "Weight": 180,
                     "Reps": 5}
                }
            }