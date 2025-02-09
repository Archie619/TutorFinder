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
    return {"Tutors": 
                {"Tutor1":
                    {"Class": "EECS2500",
                     "Rating": "5/5"},
                 "Tutor2":
                    {"Class": "EECS2510",
                     "Rating": "3.5/5"}
                }
            }