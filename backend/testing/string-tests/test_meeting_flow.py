import pytest
import pytest_asyncio
from ...routers.conversation import (ConversationSpecification, MeetingResponse, 
                                     create_meeting, load_meeting)
from ..constants import USERNAME_1, USERNAME_2
from ..build_dummies import (build_user, build_class, build_usercourse_link,
                             build_post, build_conversation)
from ..kill_dummies import (kill_user, kill_course, kill_usercourse,
                            kill_post, kill_conversation)

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
    yield conv_id

    # wipe the DB of dummy data
    kill_conversation(pid)
    kill_post(cid)
    kill_usercourse(uid_1)
    kill_usercourse(uid_2)
    kill_user(uid_1)
    kill_user(uid_2)
    kill_course()



'''
This test checks the create meeting -> load meeting flow
'''
@pytest.mark.asyncio
async def test_meeting_flow(setup_and_teardown):

    conv_id = setup_and_teardown

    # request to create a meeting
    request_json = {'conversation_id': conv_id}
    request = ConversationSpecification(**request_json)

    response_json = await create_meeting(request)
    response = MeetingResponse(**response_json)

    # confirm a meeting is created
    assert response.meeting_link

    # save this meeting link
    created_meeting = response.meeting_link

    # now request to load the meeting that was just created
    response_json = await load_meeting(request)
    response = MeetingResponse(**response_json)

    # confirm the same meeting is loaded
    assert created_meeting == response.meeting_link
