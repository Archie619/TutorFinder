import pytest
import pytest_asyncio
from ...routers.classes import (search_classes, add_class, load_classes,
                               AddUserToClassSpecification, 
                               AddClassResponse, LoadClassesResponse,
                               SearchClassesResponse)
from ..constants import USERNAME_1, DESIGNATION, DEPT, ID, COURSENAME
from ..build_dummies import build_user
from ..kill_dummies import kill_course, kill_user, kill_usercourse

########################################
#             FUNCTIONS                #
########################################

@pytest_asyncio.fixture(scope='module', autouse=True)
async def setup_and_teardown():

    # create dummies as needed
    uid, token = await build_user(USERNAME_1)
        
    # wait for tests in this module to complete
    yield token

    # wipe DB of test data
    kill_usercourse(uid)
    kill_user(uid)
    kill_course()



@pytest.mark.asyncio
async def test_add_class(setup_and_teardown):

    # create the user and class specification
    user_class_json = {'token': setup_and_teardown,
                       'designation': DESIGNATION,
                       'dept': DEPT,
                       'id': ID,
                       'name': COURSENAME}
    user_class_spec = AddUserToClassSpecification(**user_class_json)

    # add the user to the class
    response_json = await add_class(user_class_spec)
    response = AddClassResponse(**response_json)
    
    # confirm valid addition of user to class
    assert response.valid



@pytest.mark.asyncio
async def test_search_classes():

    # make a search request for classes that match the specifications
    response_json = await search_classes(DEPT, ID, COURSENAME)
    response = SearchClassesResponse(**response_json)

    # confirm the created class is returned
    assert response.classes[0] == 'ABCD 1234 Intro to Pytest'



@pytest.mark.asyncio
async def test_load_classes(setup_and_teardown):

    # make a load request for the classes of that user
    response_json = await load_classes(setup_and_teardown)
    response = LoadClassesResponse(**response_json)

    # confirm validity and that the class we created/added our
    # dummy user to is returned
    assert response.valid
    assert response.classes[0].name == 'ABCD 1234 Intro to Pytest'