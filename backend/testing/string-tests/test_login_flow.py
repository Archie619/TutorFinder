import pytest
import pytest_asyncio
from ...routers.login import login, signup, User, SignupResponse, LoginResponse
from ...db_init import cursor
from ..constants import USERNAME_1, PASSWORD

########################################
#             FUNCTIONS                #
########################################

@pytest_asyncio.fixture(scope='module', autouse=True)
async def teardown():

    # wait for tests in module to complete
    yield
    
    # remove user from the DB
    cursor.execute('DELETE FROM Users WHERE Username = ?', (USERNAME_1,))
    cursor.commit()



'''
This test checks the signup -> login flow
'''
@pytest.mark.asyncio
async def test_login_flow():

    # create a signup request
    signup_json = {'username': USERNAME_1,
                   'password': PASSWORD}
    user = User(**signup_json)

    # signup the user
    response_json = await signup(user)
    response = SignupResponse(**response_json)

    # confirm valid signup
    assert response.valid

    # attempt to login the newly signed up user
    login_json = {'username': response.user,
                  'password': PASSWORD}
    user = User(**login_json)

    response_json = await login(user)
    response = LoginResponse(**response_json)

    # confirm the user was logged in successfully
    assert response.valid
