import pytest
import pytest_asyncio
import datetime
from ..routers.profile import (profile, changeProfilePic, 
                               changePassword, 
                               User as UserToken, 
                               PasswordChangeResponse,
                               ProfileGetResponse)
from ..db_init import cursor
from ..routers.login import login, signup, User, LoginResponse

########################################
#             FUNCTIONS                #
########################################

USERNAME = 'TestUser123'
PASSWORD = 'Password123'

@pytest_asyncio.fixture(scope='module', autouse=True)
async def setup_and_teardown():

    ################
    # Create Dummy #
    ################

    user_json = {'username': USERNAME,
                 'password': PASSWORD}
    user = User(**user_json)

    # signup/login the dummy
    await signup(user) # Signup dummy
    response_json = await login(user) # login dummy
    token = LoginResponse(**response_json).token # Recieve token from login
    
    ################
    # Test Profile #
    ################

    # wait for tests in this module to complete
    yield token

    ################
    # Remove Dummy #
    ################

    # remove the dummy user from the DB
    cursor.execute('DELETE FROM Users WHERE Username = ?', (USERNAME,))

    cursor.commit()



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
