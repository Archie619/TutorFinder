import pytest
import pytest_asyncio
from ..routers.class_posts import (load_class, create_post, OneClass,
                                   ClassPosts, PostCreatedResponse,
                                   PostSpecification)
from .constants import USERNAME_1, POST_DESCRIPTION
from .build_dummies import build_user, build_class, build_usercourse_link
from .kill_dummies import kill_user, kill_course, kill_usercourse, kill_post

########################################
#             FUNCTIONS                #
########################################

@pytest_asyncio.fixture(scope='module', autouse=True)
async def setup_and_teardown():

    # create dummies as needed
    uid, token = await build_user(USERNAME_1)
    cid = build_class()    
    build_usercourse_link(uid, cid)

    # wait for tests in this module to complete
    yield token, cid

    # wipe DB of test data
    kill_post(cid)
    kill_usercourse(uid)
    kill_user(uid)
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
