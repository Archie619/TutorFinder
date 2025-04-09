import pytest
import pytest_asyncio
from ...routers.classes import (search_classes, add_class, load_classes,
                               AddUserToClassSpecification, 
                               AddClassResponse, LoadClassesResponse,
                               SearchClassesResponse)
from ..constants import USERNAME_1, DESIGNATION, DEPT, ID, COURSENAME
from ..build_dummies import build_user, build_class
from ..kill_dummies import kill_course, kill_user, kill_usercourse

########################################
#             FUNCTIONS                #
########################################

@pytest_asyncio.fixture(scope='module', autouse=True)
async def setup_and_teardown():

    # create dummies as needed
    uid, token = await build_user(USERNAME_1)
    cid = build_class()
        
    # wait for tests in this module to complete
    yield token

    # wipe DB of test data
    kill_usercourse(uid)
    kill_user(uid)
    kill_course()



'''
This test checks the search class -> add class -> view classes flow
'''
@pytest.mark.asyncio
async def test_classes_flow(setup_and_teardown):

    token = setup_and_teardown

    response_json = await search_classes(DEPT, ID, COURSENAME)
    response = SearchClassesResponse(**response_json)

    # confirm the created class is returned
    assert response.classes[0] == 'ABCD 1234 Intro to Pytest'

    # make a request to add this searched class to the user's classes
    user_class_json = {'token': token,
                       'designation': DESIGNATION,
                       'dept': DEPT,
                       'id': ID,
                       'name': COURSENAME}
    user_class_spec = AddUserToClassSpecification(**user_class_json)

    response_json = await add_class(user_class_spec)
    response = AddClassResponse(**response_json)

    # confirm addition of the user to the class was successful
    assert response.valid

    response_json = await load_classes(token)
    response = LoadClassesResponse(**response_json)

    # confirm the class is in the user's class list
    assert response.valid
    assert response.classes[0].name == 'ABCD 1234 Intro to Pytest'
