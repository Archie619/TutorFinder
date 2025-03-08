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

class AddUserToClassSpecification(BaseModel):
    token: str
    designation: str
    dept: str
    id: str
    name: str

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

    username = None
    validity = True
    errormsg = None

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
async def add_class(request: AddUserToClassSpecification):

    # decode the token
    user, valid, errormsg = decode_token(request)

    # confirm designation is 'student' or 'tutor'
    if request.designation not in ['student', 'tutor']:
        valid = False
        errormsg = 'invalid designation'

    if valid:
        # check if the requested class exists
        cursor.execute('SELECT CourseID '
                       'FROM Courses '
                       'WHERE CourseDept = ? AND CourseDeptID = ? AND CourseName = ?',
                       (request.dept, request.id, request.name))
        cid = cursor.fetchone()
        
        # if the requested class doesn't exist, create it
        if cid is None:
            cursor.execute('INSERT INTO Courses VALUES (?, ?, ?)', 
                        (request.dept, request.id, request.name))
            cursor.commit()
            cursor.execute('SELECT CourseID '
                           'FROM Courses '
                           'WHERE CourseDept = ? AND CourseDeptID = ? AND CourseName = ?',
                           (request.dept, request.id, request.name))
            cid = cursor.fetchone()
        
        cid = cid[0]
        
        # grab the UserID for the user
        cursor.execute('SELECT UserID FROM Users WHERE Username = ?', (user,))
        uid = cursor.fetchone()[0]
        
        # confirm user is not already in the class
        cursor.execute('SELECT UserID FROM UserCourses WHERE UserID = ? AND CourseID = ?', (uid, cid))
        inclass = cursor.fetchone()

        if not inclass:
            cursor.execute('INSERT INTO UserCourses VALUES (?, ?, ?)', (uid, cid, request.designation))
            cursor.commit()
        else:
            valid = False
            errormsg = 'user already in class'

    addedclass = request.dept + ' ' + request.id + ' ' + request.name

    return {'username': user,
            'addedclass': addedclass,
            'valid': valid,
            'errormsg': errormsg}



'''
Retrieve user's classes, user determined by their token
'''
@router.get('/classes', response_model=LoadClassesResponse)
async def load_classes(token: UserToken):

    classes = []

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
