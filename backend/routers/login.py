from fastapi import APIRouter
from pydantic import BaseModel
from ..db_init import cursor

router = APIRouter()

########################################
#           PYDANTIC MODELS            #
########################################

class User(BaseModel):
    username: str
    password: str

class LoginRespone(BaseModel):
    token: str | None
    valid: bool
    errormsg: str | None

class SignupResponse(BaseModel):
    user: str
    valid: bool
    errormsg: str | None

########################################
#             FUNCTIONS                #
########################################

"""
Check if username and password follow alphanumeric and
length rules
"""
def len_alphnum_check(username: str, password: str):
    
    validity = True
    errormessage = None

    # validate username, basic length & alphanumeric check
    if (len(username) <= 0  or 
        len(username) >= 30 or
        not username.isalnum()):
        validity = False
        errormessage = 'username len/alphanum'

    # validate password, basic length check
    if (len(password) <= 0  or 
        len(password) >= 30):
        validity = False
        if errormessage == 'username len/alphanum':
            errormessage = 'username & password len/alphanum'
        else:
            errormessage = 'password len/alphanum'
    
    return validity, errormessage



"""
Allow user to login to the system
"""
@router.post('/login', response_model=LoginRespone)
async def login(user: User):

    # token is what user gets if/when they successfully login
    token = None

    # verify length and alphanumeric of username and password
    valid, errormsg = len_alphnum_check(user.username, user.password)

    # check the database to see if username exists
    if valid:
        cursor.execute("SELECT Username, Password FROM Users WHERE Username = ?", (user.username,))
        exists = cursor.fetchone()
        if exists:
            # check if password for that username is correct
            if exists[1] == user.password:
                #########################################
                #  MAKE THIS A REAL TOKEN LOGIN SYSTEM  #
                #########################################
                token = 'hjabdijhawbdiuawndawndiwndoiwadnaoindsdn'
            else:
                valid = False
                errormsg = 'password is not correct'
        else:
            valid = False
            errormsg = 'username does not exist'

    return {'token': token, 
            'valid': valid,
            'errormsg': errormsg}



"""
Allow user to signup for the system
"""
@router.post('/signup', response_model=SignupResponse)
async def signup(user: User):

    # verify length and alphanumeric of username and password
    valid, errormsg = len_alphnum_check(user.username, user.password)

    # check the database to see if username already exists
    if valid:
        cursor.execute("SELECT Username FROM Users WHERE Username = ?", (user.username,))
        exists = cursor.fetchone()
        if exists:
            valid = False
            errormsg = 'username exists'
        else:
            # create new entry for the new user
            cursor.execute("INSERT INTO Users VALUES (?, ?)", (user.username, user.password))
            cursor.commit()

    return {'user': user.username,
            'valid': valid,
            'errormsg': errormsg}
