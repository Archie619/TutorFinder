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
    
    # remove dummy user from the DB
    cursor.execute('DELETE FROM Users WHERE Username = ?', (USERNAME_1,))
    cursor.commit()



@pytest.mark.asyncio
async def test_signup():
    
    signup_json = {'username': USERNAME_1, 
                   'password': PASSWORD}
    user = User(**signup_json)
    response_json = await signup(user)
    response = SignupResponse(**response_json)

    # confirm valid signup
    assert response.valid



@pytest.mark.asyncio
async def test_login():
    
    login_json = {'username': USERNAME_1,
                  'password': PASSWORD}
    user = User(**login_json)
    response_json = await login(user)
    response = LoginResponse(**response_json)

    # confirm valid login
    assert response.valid
