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

    valid = True
    errormsg = 'none'

    # validate username, basic length & alphanumeric check
    if (len(user.username) <= 0  or 
        len(user.username) >= 30 or
        not user.username.isalnum()):
        valid = False
        errormsg = 'username'

    # validate password, basic length check
    if (len(user.password) <= 0  or 
        len(user.password) >= 30):
        valid = False
        if errormsg == 'username':
            errormsg = 'username+password'
        else:
            errormsg = 'password'

    # check the database to see if username already exists
    # create new entry for the new user
    return {'user': user.username,
            'valid': valid,
            'errormsg': errormsg}