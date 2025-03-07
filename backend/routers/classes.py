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

class ClassSpecification(BaseModel):
    dept: str | None
    id: str | None
    name: str | None

class AddClassResponse(BaseModel):
    username: str | None
    addedclass: str | None
    valid: bool
    errormsg: str | None

class LoadClassesResponse(BaseModel):
    username: str | None
    classes: list[str]
    valid: bool
    errormsg: str | None

class SearchClassesResponse(BaseModel):
    classes: list[str]

########################################
#             FUNCTIONS                #
########################################

'''
Decode a user token, check validity
'''
def decode_token(usertoken: UserToken):

    try: 
        payload = jwt.decode(usertoken.token, 
                             os.environ['TF_TokenizerKeyDecoder'],
                             'RS256')
        username = payload['username']

        # check token expiration
        if (datetime.datetime.strptime(payload['expiration'], "%Y-%m-%dT%H:%M:%S.%f%z") 
            <= datetime.datetime.now(datetime.timezone.utc)):
            validity = False
            errormsg = 'expired token'

    except jwt.InvalidTokenError:
        validity = False
        errormsg = 'invalid token'
    
    return username, validity, errormsg



'''
Add a user to a class
'''
@router.post('/classes/add', response_model=AddClassResponse)
async def add_class(request: ClassSpecification):

    user = None
    classtoadd = None
    valid = True
    errormsg = None

    # decode the token
    user, valid, errormsg = decode_token(request)

    # check if the requested class exists

    return {'username': user,
            'addedclass': classtoadd,
            'valid': valid,
            'errormsg': errormsg}



'''
Retrieve user's classes, user determined by their token
'''
@router.get('/classes', response_model=LoadClassesResponse)
async def load_classes(token: UserToken):
    
    user = None
    classes = []
    valid = True
    errormsg = None

    # decode the token
    user, valid, errormsg = decode_token(token)

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



'''
Search for classes given specifications
'''
@router.get('/classes/filter', response_model=SearchClassesResponse)
async def search_classes(spec: ClassSpecification):

    # base search command
    command = ('SELECT CourseDept, CourseDeptID, CourseName '
               'FROM Courses '
               'WHERE ')

    # append to base command w/user supplied specs
    if spec.dept is not None: command += 'CourseDept LIKE ? '
    if spec.id is not None: command += 'AND CourseDeptID LIKE ? '
    if spec.name is not None: command += 'AND CourseName LIKE ?'

    # (if needed) delete leading AND
    if command.find('AND') == 63:
        command = command[:62] + command[66:]
        
    # (if needed) remove WHERE if no filters were applied
    command = command.removesuffix('WHERE ')

    # create the tuple for applied specs
    specs = tuple('%' + x + '%' for x in [spec.dept, spec.id, spec.name] if x is not None)
    
    # search the DB for classes that match the class specifications
    cursor.execute(command, specs)
    
    classes = cursor.fetchall()

    # format the tuples returned into a string
    for i, one_class in enumerate(classes):
        classes[i] = ' '.join(item for item in one_class)

    return {'classes': classes}
