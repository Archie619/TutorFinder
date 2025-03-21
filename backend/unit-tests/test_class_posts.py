import pytest
import pytest_asyncio
from .test_login import USERNAME, PASSWORD
from .test_classes import DEPT, ID, NAME
from ..routers.class_posts import (load_class, create_post, OneClass,
                                   ClassPosts, PostCreatedResponse,
                                   PostSpecification)
from ..routers.login import login, signup, User, LoginResponse
from ..db_init import cursor

POST_DESCRIPTION = 'PYTEST TEST DESC'

########################################
#             FUNCTIONS                #
########################################

@pytest_asyncio.fixture(scope='module', autouse=True)
async def setup_and_teardown():

    # create a dummy user
    user_json = {'username': USERNAME,
                 'password': PASSWORD}
    user = User(**user_json)

    # create a dummy class
    cursor.execute('INSERT INTO Courses '
                   'VALUES (?, ?, ?)', (DEPT, ID, NAME))
    
    # grab the dummy classes CourseID
    cursor.execute('SELECT CourseID '
                   'FROM Courses '
                   'WHERE CourseDept = ? AND CourseDeptID = ? AND CourseName = ?',
                   (DEPT, ID, NAME))
    cid = cursor.fetchone()[0]

    # signup / login the dummy
    await signup(user)
    response_json = await login(user)
    token = LoginResponse(**response_json).token

    # wait for tests in this module to complete
    yield token, cid

    # grab the dummy user's UserID
    cursor.execute('SELECT UserID FROM Users WHERE Username = ?', (USERNAME,))
    uid = cursor.fetchone()[0]

    # remove the dummy post from the DB
    cursor.execute('DELETE FROM Posts '
                   'WHERE OwnerCourseID = ?', (cid,))
    # remove the dummy user from the DB
    cursor.execute('DELETE FROM Users WHERE Username = ?', (USERNAME,))
    # remove the dummy class from the DB
    cursor.execute('DELETE FROM Courses ' 
                   'WHERE CourseDept = ? AND CourseDeptID = ? AND CourseName = ?',
                   (DEPT, ID, NAME))
    cursor.commit()



@pytest.mark.asyncio
async def test_create_post(setup_and_teardown):
    
    # create the spec
    token, cid = setup_and_teardown
    request_json = {'token': token,
                    'class_id': cid,
                    'post_description': POST_DESCRIPTION}
    request = PostSpecification(**request_json)

    # request to create the post
    response_json = await create_post(request)
    response = PostCreatedResponse(**response_json)

    # confirm the post was created
    assert response.valid



@pytest.mark.asyncio
async def test_load_class(setup_and_teardown):
    
    # create the spec
    token, cid = setup_and_teardown
    test_class = OneClass(**{'class_id': cid})

    # request to load the class
    response_json = await load_class(test_class)
    response = ClassPosts(**response_json)

    # confirm post was created
    assert response.posts[0]
