from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()

########################################
#           PYDANTIC MODELS            #
########################################

class User(BaseModel):
    username: str
    password: str

########################################
#              FUNCTIONS               #
########################################

"""
Allow user to login to the system
"""
@router.post('/login')
async def login(user: User):
    # validate username and password, basic length & char check
    # check the database to see if username exists
    # check if password for that username is correct
    return {'user': user.username, 'status': 'valid'}

"""
Allow user to signup for the system
"""
@router.post('/signup')
async def signup(user: User):
    # validate username and password, basic length & char check
    # check the database to see if username already exists
    # create new entry for the new user
    return {'signup': 'successful'}