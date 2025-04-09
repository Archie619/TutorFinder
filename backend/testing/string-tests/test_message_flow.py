import pytest
import pytest_asyncio
from ...routers.post import (PostSpecification, ConfirmationResponse,
                             PostDetails, PostContacts, load_post, 
                             add_user_to_post, load_contacts)
from ...routers.conversation import (AddConversationSpecification, ConvoCreationResponse,
                                     ConvoMessages, MessageSpecification, add_conversation, 
                                     store_message, load_conversation)
from ..constants import USERNAME_1, USERNAME_2, POST_DESCRIPTION, MESSAGE_1
from ..build_dummies import (build_user, build_class, 
                             build_usercourse_link, build_post)
from ..kill_dummies import (kill_user, kill_course, kill_usercourse,
                            kill_post, kill_userpost_link, kill_conversation,
                            kill_conversation_tie, kill_message)

conv_id = None

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

    # build a post where user 2 is the owner
    pid = build_post(uid_2, cid)
    request_json = {'token': token_2,
                    'post_id': pid,
                    'rating': None,
                    'search_username': None}
    request = PostSpecification(**request_json)
    await add_user_to_post(request)

    # wait for tests in this module to complete
    yield token_1, token_2, pid

    # wipe DB of test data
    kill_message(conv_id)
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



'''
This test checks the view post -> join post -> create conversation -> 
send message -> view message flow
'''
@pytest.mark.asyncio
async def test_message_flow(setup_and_teardown):

    token_1, token_2, pid = setup_and_teardown

    # request to view the post
    response_json = await load_post(token_1, pid)
    response = PostDetails(**response_json)

    # confirm the post was loaded
    assert response.valid
    assert response.desc == POST_DESCRIPTION

    # request to join the loaded post
    request_json = {'token': token_1,
                    'post_id': pid,
                    'rating': None,
                    'search_username': None}
    request = PostSpecification(**request_json)

    response_json = await add_user_to_post(request)
    response = ConfirmationResponse(**response_json)

    # confirm the user was added to the post group
    assert response.valid

    # request to create a conversation with user 2 (the post owner)
    request_json = {'token': token_1,
                    'convo_partners': [USERNAME_2],
                    'post_id': pid}
    request = AddConversationSpecification(**request_json)

    response_json = await add_conversation(request)
    response = ConvoCreationResponse(**response_json)

    # confirm the conversation is created successfully
    assert response.valid

    global conv_id
    conv_id = response.conversation_id

    # request to send (store) a message in the conversation
    request_json = {'token': token_1,
                    'conversation_id': conv_id,
                    'message': MESSAGE_1}
    request = MessageSpecification(**request_json)

    response_json = await store_message(request)
    response = ConfirmationResponse(**response_json)

    # confirm the message was stored successfully
    assert response.valid

    # AS USER 2, request to load contacts
    response_json = await load_contacts(token_2, pid)
    response = PostContacts(**response_json)

    # confirm a contact with user 1 loads
    assert response.valid
    assert response.contacts[0].names[0] == USERNAME_1

    # AS USER 2, request to view the conversation
    response_json = await load_conversation(response.contacts[0].conversation_id)
    response = ConvoMessages(**response_json)

    # confirm the message sent by user 1 loads
    assert response.convo[0]['User'] == USERNAME_1
    assert response.convo[0]['Message'] == MESSAGE_1
