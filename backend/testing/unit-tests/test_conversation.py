import pytest
import pytest_asyncio
from ...routers.conversation import (AddConversationSpecification, ConvoCreationResponse,
                                    ConversationSpecification, ConvoMessages,
                                    MessageSpecification, ConfirmationResponse,
                                    MeetingResponse, add_conversation, load_conversation,
                                    store_message, create_meeting, load_meeting)
from ...db_init import cursor
from ..constants import USERNAME_1, USERNAME_2, MESSAGE_1, MESSAGE_2
from ..build_dummies import (build_user, build_class, 
                           build_usercourse_link, build_post)
from ..kill_dummies import (kill_user, kill_course, kill_usercourse,
                           kill_post, kill_userpost_link, kill_conversation,
                           kill_conversation_tie, kill_message)

conv_id = None
meeting_link = None

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



@pytest.mark.asyncio
async def test_add_conversation(setup_and_teardown):

    # create the spec
    token_1, token_2, pid = setup_and_teardown
    request_json = {'token': token_1,
                    'convo_partners': [USERNAME_2],
                    'post_id': pid}
    request = AddConversationSpecification(**request_json)

    # request to add the dummy conversation
    response_json = await add_conversation(request)
    response = ConvoCreationResponse(**response_json)

    # save the conversation id in a global var
    global conv_id 
    conv_id = response.conversation_id

    # confirm the response was valid
    assert response.valid

    # check that the new conversation is in the DB
    cursor.execute('SELECT PostID FROM Conversations '
                   'WHERE ConversationID = ?', (response.conversation_id,))
    assert cursor.fetchone()[0] == pid



@pytest.mark.asyncio
async def test_store_message(setup_and_teardown):

    # create the spec
    token_1, token_2, pid = setup_and_teardown
    request_json_1 = {'token': token_1,
                    'conversation_id': conv_id,
                    'message': MESSAGE_1}
    request_json_2 = {'token': token_2,
                    'conversation_id': conv_id,
                    'message': MESSAGE_2}
    request_1 = MessageSpecification(**request_json_1)
    request_2 = MessageSpecification(**request_json_2)

    # request to store the two dummy messages
    response_json_1 = await store_message(request_1)
    response_1 = ConfirmationResponse(**response_json_1)
    response_json_2 = await store_message(request_2)
    response_2 = ConfirmationResponse(**response_json_2)

    # confirm the messages were stored
    assert response_1.valid
    assert response_2.valid



@pytest.mark.asyncio
async def test_load_conversation():

    # request to load the dummy conversation
    response_json = await load_conversation(conv_id)
    response = ConvoMessages(**response_json)

    # confirm the dummy messages are returned
    assert response.convo[0]['User'] == USERNAME_1
    assert response.convo[0]['Message'] == MESSAGE_1
    assert response.convo[1]['User'] == USERNAME_2
    assert response.convo[1]['Message'] == MESSAGE_2



@pytest.mark.asyncio
async def test_create_meeting():

    # create the spec
    request_json = {'conversation_id': conv_id}
    request = ConversationSpecification(**request_json)

    # request to create a dummy meeting for the conversation
    response_json = await create_meeting(request)
    response = MeetingResponse(**response_json)

    # save the meeting link in a global var
    global meeting_link
    meeting_link = response.meeting_link

    # confirm a meeting link was created
    assert response.meeting_link.startswith('https://meet.jit.si/TutorFinder-')



@pytest.mark.asyncio
async def test_load_meeting():

    # request to load the dummy meeting for the conversation
    response_json = await load_meeting(conv_id)
    response = MeetingResponse(**response_json)

    # confirm the meeting link is the same as the one we just created
    assert response.meeting_link == meeting_link
