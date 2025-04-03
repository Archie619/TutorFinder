from ..routers.login import login, signup, User, LoginResponse
from ..db_init import cursor
from .constants import (PASSWORD, DEPT, ID, COURSENAME, 
                       RATING, RATINGSLEFT, POST_DESCRIPTION)

########################################
#             FUNCTIONS                #
########################################

async def build_user(username):
    # create a dummy user
    user_json = {'username': username,
                 'password': PASSWORD}
    user = User(**user_json)

    # signup / login the dummy
    await signup(user)
    response_json = await login(user)
    token = LoginResponse(**response_json).token

    # grab the dummy user's UserID
    cursor.execute('SELECT UserID FROM Users WHERE Username = ?', (username,))
    uid = cursor.fetchone()[0]

    return uid, token



def build_class():
    # create a dummy class
    cursor.execute('INSERT INTO Courses '
                   'VALUES (?, ?, ?)', (DEPT, ID, COURSENAME))
    cursor.commit()
    
    # grab the dummy classes CourseID
    cursor.execute('SELECT CourseID '
                   'FROM Courses '
                   'WHERE CourseDept = ? AND CourseDeptID = ? AND CourseName = ?',
                   (DEPT, ID, COURSENAME))
    cid = cursor.fetchone()[0]
    return cid



def build_usercourse_link(uid, cid):
    # create a link between the dummy user and dummy class
    cursor.execute('INSERT INTO UserCourses VALUES (?, ?, ?)', (uid, cid, "tutor"))
    cursor.commit()



def build_post(uid, cid):
    # create a dummy post
    cursor.execute('INSERT INTO Posts '
                   'VALUES (?, ?, ?, ?, ?)',
                   (uid, cid, RATING, POST_DESCRIPTION, RATINGSLEFT))
    cursor.commit()

    # grab the dummy PostID
    cursor.execute('SELECT PostID FROM Posts '
                   'WHERE OwnerCourseID = ?', cid)
    pid = cursor.fetchone()[0]
    return pid



def build_conversation(pid):
    # create a conversation on the post
    cursor.execute('INSERT INTO Conversations '
                   'VALUES (?, ?)', (pid, None))
    cursor.commit()

    # grab the ConversationID
    cursor.execute('SELECT ConversationID FROM Conversations '
                   'WHERE PostID = ?', (pid,))
    conv_id = cursor.fetchone()[0]
    return conv_id
