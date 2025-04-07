from ..db_init import cursor
from .constants import DEPT, ID, COURSENAME

########################################
#             FUNCTIONS                #
########################################

def kill_user(uid):
    # remove the dummy user from the DB
    cursor.execute('DELETE FROM Users WHERE UserID = ?', (uid,))
    cursor.commit()



def kill_usercourse(uid):
    # remove the dummy UserCourses link
    cursor.execute('DELETE FROM UserCourses WHERE UserID = ?', (uid,))
    cursor.commit()



def kill_course():
    # remove the dummy class from the DB
    cursor.execute('DELETE FROM Courses ' 
                   'WHERE CourseDept = ? AND CourseDeptID = ? AND CourseName = ?',
                   (DEPT, ID, COURSENAME))
    cursor.commit()



def kill_post(cid):
    # remove the dummy post from the DB
    cursor.execute('DELETE FROM Posts '
                   'WHERE OwnerCourseID = ?', (cid,))
    cursor.commit()



def kill_userpost_link(uid):
    # remove the link between the dummy user and dummy post
    cursor.execute('DELETE FROM UserPosts WHERE UserID = ? ', (uid,))
    cursor.commit()



def kill_conversation(pid):
    # remove the conversation linked to a dummy post
    cursor.execute('DELETE FROM Conversations WHERE PostID = ? ', (pid,))
    cursor.commit()



def kill_conversation_tie(conv_id):
    # remove the conversation link between users
    cursor.execute('DELETE FROM UserConversations WHERE ConversationID = ?', (conv_id,))
    cursor.commit()



def kill_message(conv_id):
    # remove dummy messages linked to a dummy conversation
    cursor.execute('DELETE FROM Messages WHERE ConversationID = ?', (conv_id,))
    cursor.commit()
