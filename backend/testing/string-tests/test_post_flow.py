import pytest
import pytest_asyncio
from ...routers.class_posts import (load_class, create_post, ClassPosts, PostCreatedResponse,
                                   PostSpecification as PostSpecificationClass)
from ...routers.post import (PostDetails, load_post)
from ..constants import USERNAME_1, POST_DESCRIPTION
from ..build_dummies import build_user, build_class, build_usercourse_link
from ..kill_dummies import kill_user, kill_course, kill_usercourse, kill_post

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



'''
This test checks the create post (for class) -> view class -> view post flow
'''
@pytest.mark.asyncio
async def test_post_flow(setup_and_teardown):

    token, cid = setup_and_teardown

    # request to create a post for the class
    request_json = {'token': token,
                    'class_id': cid,
                    'post_description': POST_DESCRIPTION}
    request = PostSpecificationClass(**request_json)

    response_json = await create_post(request)
    response = PostCreatedResponse(**response_json)

    # confirm post was created successfully
    assert response.valid

    # request to view the class
    response_json = await load_class(cid)
    response = ClassPosts(**response_json)

    # confirm the created post is returned
    assert response.posts[0].name == USERNAME_1

    # request to view the post (in detail)
    response_json = await load_post(token, response.posts[0].post_id)
    response = PostDetails(**response_json)

    # confirm the created post loads
    assert response.valid
    assert response.desc == POST_DESCRIPTION
