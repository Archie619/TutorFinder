import datetime
import jwt
import os
from fastapi import APIRouter
from pydantic import BaseModel
from ..db_init import cursor

router = APIRouter()

########################################
#           PYDANTIC MODELS            #
########################################

class UserToken(BaseModel):
    token: str

class LoadClassesResponse(BaseModel):
    username: str | None
    classes: list[str]
    valid: bool
    errormsg: str | None

########################################
#             FUNCTIONS                #
########################################

'''
Retrieve user's classes, user determined by their token
'''
@router.get('/classes', response_model=LoadClassesResponse)
async def load_classes(usertoken: UserToken):
    
    user = None
    classes = []
    valid = True
    errormsg = None

    # decode the token
    try: 
        payload = jwt.decode(usertoken.token, 
                             os.environ['TF_TokenizerKeyDecoder'],
                             'RS256')
        user = payload['username']

        # check token expiration
        if (datetime.datetime.strptime(payload['expiration'], "%Y-%m-%dT%H:%M:%S.%f%z") 
            <= datetime.datetime.now(datetime.timezone.utc)):
            valid = False
            errormsg = 'expired token'

    except jwt.InvalidTokenError:
        valid = False
        errormsg = 'invalid token'

    # retrieve the user's classes from the database
    if valid:
        cursor.execute('SELECT CourseDept, CourseDeptID, CourseName '
                       'FROM Courses AS c '
                            'JOIN UserCourses AS uc '
                                'ON c.CourseID = uc.CourseID '
                            'JOIN Users AS u '
                                'ON uc.UserID = u.UserID '
                       'WHERE u.Username = ?', (user,))
        classes = cursor.fetchall()

        # format the tuples returned into a string
        for i, one_class in enumerate(classes):
            classes[i] = ' '.join(item for item in one_class)

    return {'username': user,
            'classes': classes,
            'valid': valid,
            'errormsg': errormsg}
