import pytest
import pytest_asyncio
from .test_login import USERNAME, PASSWORD
from ..routers.classes import (search_classes, add_class, load_classes,
                               UserToken, ClassSpecification,
                               AddUserToClassSpecification, 
                               AddClassResponse, LoadClassesResponse,
                               SearchClassesResponse)
from ..routers.login import login, signup, User, LoginResponse
from ..db_init import cursor

DESIGNATION = 'student'
DEPT = 'ABCD'
ID = '1234'
NAME = 'Intro to Pytest'

########################################
#             FUNCTIONS                #
########################################

@pytest_asyncio.fixture(scope='module', autouse=True)
async def setup_and_teardown():

    # create a dummy user
    user_json = {'username': USERNAME,
                 'password': PASSWORD}
    user = User(**user_json)

    # signup / login the dummy
    await signup(user)
    response_json = await login(user)
    token = LoginResponse(**response_json).token
    
    # wait for tests in this module to complete
    yield token

    # grab the dummy user's UserID
    cursor.execute('SELECT UserID FROM Users WHERE Username = ?', (USERNAME,))
    uid = cursor.fetchone()[0]

    # remove the dummy UserCourses link
    cursor.execute('DELETE FROM UserCourses WHERE UserID = ?', (uid,))
    # remove the dummy user from the DB
    cursor.execute('DELETE FROM Users WHERE Username = ?', (USERNAME,))
    # remove the dummy class from the DB
    cursor.execute('DELETE FROM Courses ' 
                   'WHERE CourseDept = ? AND CourseDeptID = ? AND CourseName = ?',
                   (DEPT, ID, NAME))
    cursor.commit()



@pytest.mark.asyncio
async def test_add_class(setup_and_teardown):

    # create the user and class specification
    user_class_json = {'token': setup_and_teardown,
                       'designation': DESIGNATION,
                       'dept': DEPT,
                       'id': ID,
                       'name': NAME}
    user_class_spec = AddUserToClassSpecification(**user_class_json)

    # add the user to the class
    response_json = await add_class(user_class_spec)
    response = AddClassResponse(**response_json)
    
    # confirm valid addition of user to class
    assert response.valid



@pytest.mark.asyncio
async def test_search_classes():

    # create a search specification based on the class we created above
    class_json = {'dept': DEPT,
                  'id': ID,
                  'name': NAME}
    class_spec = ClassSpecification(**class_json)

    # make a search request for classes that match the specifications
    response_json = await search_classes(class_spec)
    response = SearchClassesResponse(**response_json)

    # confirm the created class is returned
    assert response.classes[0] == 'ABCD 1234 Intro to Pytest'



@pytest.mark.asyncio
async def test_load_classes(setup_and_teardown):

    # create a user token specification
    user_token_json = {'token': setup_and_teardown}
    user_token_spec = UserToken(**user_token_json)

    # make a load request for the classes of that user
    response_json = await load_classes(user_token_spec)
    response = LoadClassesResponse(**response_json)

    # confirm validity and that the class we created/added our
    # dummy user to is returned
    assert response.valid
    assert response.classes[0].name == 'ABCD 1234 Intro to Pytest'