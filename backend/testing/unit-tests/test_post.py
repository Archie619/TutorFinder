import pytest
import pytest_asyncio
from ...routers.post import (PostSpecification, PostDetails, ConfirmationResponse,
                            PostContacts, PostUsers, load_post, add_user_to_post,
                            rate, load_contacts, search_users)
from ...db_init import cursor
from ..constants import POST_DESCRIPTION, USERNAME_1, USERNAME_2
from ..build_dummies import (build_user, build_class, 
                           build_usercourse_link, build_post,
                           build_conversation)
from ..kill_dummies import (kill_user, kill_course, kill_usercourse,
                          kill_post, kill_userpost_link, kill_conversation,
                          kill_conversation_tie)

########################################
#             FUNCTIONS                #
########################################

@pytest_asyncio.fixture(scope='module', autouse=True)
async def setup_and_teardown():

    # create dummies as needed
    uid_1, token_1 = await build_user(USERNAME_1)
    uid_2, token_2 = await build_user(USERNAME_2)
    cid = build_class()
    build_usercourse_link(uid_1, cid)
    build_usercourse_link(uid_2, cid)
    pid = build_post(uid_1, cid)
    conv_id = build_conversation(pid)

    # wait for tests in this module to complete
    yield token_1, token_2, pid, uid_1, uid_2, conv_id

    # wipe DB of test data
    kill_conversation_tie(conv_id)
    kill_conversation(pid)
    kill_userpost_link(uid_1)
    kill_userpost_link(uid_2)
    kill_post(cid)
    kill_usercourse(uid_1)
    kill_usercourse(uid_2)
    kill_user(uid_1)
    kill_user(uid_2)
    kill_course()



@pytest.mark.asyncio
async def test_load_post(setup_and_teardown):

    # create the spec
    token_1, token_2, pid, uid_1, uid_2, conv_id = setup_and_teardown
    request_json = {'token': token_1,
                    'post_id': pid,
                    'rating': None,
                    'search_username': None}
    request = PostSpecification(**request_json)

    # request to load the dummy post
    response_json = await load_post(request)
    response = PostDetails(**response_json)

    # confirm correct post was pulled
    assert response.valid
    assert response.desc == POST_DESCRIPTION



@pytest.mark.asyncio
async def test_add_user_to_post(setup_and_teardown):

    # create the specs
    token_1, token_2, pid, uid_1, uid_2, conv_id = setup_and_teardown
    request_json_1 = {'token': token_1,
                    'post_id': pid,
                    'rating': None,
                    'search_username': None}
    request_json_2 = {'token': token_2,
                    'post_id': pid,
                    'rating': None,
                    'search_username': None}
    request_1 = PostSpecification(**request_json_1)
    request_2 = PostSpecification(**request_json_2)

    # request to add the dummy users to the dummy post
    response_json_1 = await add_user_to_post(request_1)
    response_1 = ConfirmationResponse(**response_json_1)
    response_json_2 = await add_user_to_post(request_2)
    response_2 = ConfirmationResponse(**response_json_2)

    # confirm users were added to post group
    assert response_1.valid
    assert response_2.valid



@pytest.mark.asyncio
async def test_rate(setup_and_teardown):

    # create the spec
    token_1, token_2, pid, uid_1, uid_2, conv_id = setup_and_teardown
    request_json = {'token': token_2,
                    'post_id': pid,
                    'rating': 2,
                    'search_username': None}
    request = PostSpecification(**request_json)

    # request to rate the dummy post
    response_json = await rate(request)
    response = ConfirmationResponse(**response_json)

    # confirm response was valid
    assert response.valid

    # confirm the rating was updated
    cursor.execute('SELECT Rating FROM Posts WHERE PostID = ?', (pid,))
    assert cursor.fetchone()[0] == 3



@pytest.mark.asyncio
async def test_load_contacts(setup_and_teardown):

    # create the spec
    token_1, token_2, pid, uid_1, uid_2, conv_id = setup_and_teardown
    request_json = {'token': token_1,
                    'post_id': pid,
                    'rating': 2,
                    'search_username': None}
    request = PostSpecification(**request_json)

    # create a tie to the conversation between the two dummies
    cursor.execute('INSERT INTO UserConversations '
                   'VALUES (?, ?)', (conv_id, uid_1))
    cursor.execute('INSERT INTO UserConversations '
                   'VALUES (?, ?)', (conv_id, uid_2))
    cursor.commit()

    # request to load contacts
    response_json = await load_contacts(request)
    response = PostContacts(**response_json)

    # confirm response was valid
    assert response.valid

    # confirm the listed contact of dummy 2
    assert response.contacts[0].names[0] == USERNAME_2



@pytest.mark.asyncio
async def test_search_users(setup_and_teardown):

    # create the spec
    token_1, token_2, pid, uid_1, uid_2, conv_id = setup_and_teardown
    request_json = {'token': token_1,
                    'post_id': pid,
                    'rating': None,
                    'search_username': USERNAME_2[int(len(USERNAME_2)/2):]}
    request = PostSpecification(**request_json)

    response_json = await search_users(request)
    response = PostUsers(**response_json)

    # confirm search was performed correctly
    assert response.valid
    assert response.users == [USERNAME_2]