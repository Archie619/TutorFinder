import pytest
import pytest_asyncio
from .test_classes import (DEPT, ID, NAME, build_dummy_user, kill_usercourse,
                           kill_dummy_user, kill_course)
from ..routers.class_posts import (load_class, create_post, OneClass,
                                   ClassPosts, PostCreatedResponse,
                                   PostSpecification)
from ..db_init import cursor

USERNAME = 'TestUser1'
POST_DESCRIPTION = 'PYTEST TEST DESC'

########################################
#             FUNCTIONS                #
########################################

def build_dummy_class():
    # create a dummy class
    cursor.execute('INSERT INTO Courses '
                   'VALUES (?, ?, ?)', (DEPT, ID, NAME))
    cursor.commit()
    
    # grab the dummy classes CourseID
    cursor.execute('SELECT CourseID '
                   'FROM Courses '
                   'WHERE CourseDept = ? AND CourseDeptID = ? AND CourseName = ?',
                   (DEPT, ID, NAME))
    cid = cursor.fetchone()[0]
    return cid



def build_dummy_usercourse_link(uid, cid):
    # create a link between the dummy user and dummy class
    cursor.execute('INSERT INTO UserCourses VALUES (?, ?, ?)', (uid, cid, "tutor"))
    cursor.commit()



def kill_post(cid):
    # remove the dummy post from the DB
    cursor.execute('DELETE FROM Posts '
                   'WHERE OwnerCourseID = ?', (cid,))
    cursor.commit()



@pytest_asyncio.fixture(scope='module', autouse=True)
async def setup_and_teardown():

    # create dummies as needed
    uid, token = await build_dummy_user(USERNAME)
    cid = build_dummy_class()    
    build_dummy_usercourse_link(uid, cid)

    # wait for tests in this module to complete
    yield token, cid

    # wipe DB of test data
    kill_post(cid)
    kill_usercourse(uid)
    kill_dummy_user(uid)
    kill_course()



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
