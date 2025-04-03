import pytest
import pytest_asyncio
import datetime
from ..routers.profile import (profile, 
                               changePassword, 
                               User as UserToken, 
                               PasswordChangeResponse,
                               ProfileGetResponse)
from .constants import USERNAME_1
from .build_dummies import build_user
from .kill_dummies import kill_user

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
    kill_user(uid)



@pytest.mark.asyncio
async def test_change_password(setup_and_teardown):
    
    # create a user token specification
    user_token_json = {'token': setup_and_teardown, 'password': "PasswordChanged"}
    user_token_spec = UserToken(**user_token_json)

    response_json = await changePassword(user_token_spec)
    response = PasswordChangeResponse(**response_json)

    # confirm validity
    assert response.valid



@pytest.mark.asyncio
async def test_get_profile(setup_and_teardown):

    # create a user token specification
    user_token_json = {'token': setup_and_teardown, 'password': "PasswordChanged"}
    user_token_spec = UserToken(**user_token_json)

    response_json = await profile(user_token_spec)
    response = ProfileGetResponse(**response_json)

    # confirm validity
    assert response.valid
    assert response.joindate == datetime.datetime.today().strftime('%Y-%m-%d')
