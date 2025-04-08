from fastapi import APIRouter, Header
from pydantic import BaseModel
from typing import Optional
from ..db_init import cursor
from .login import decode_token

router = APIRouter()

########################################
#           PYDANTIC MODELS            #
########################################

class PostSpecification(BaseModel):
    token: str
    post_id: int
    rating: float | None
    search_username: str | None

class PostDetails(BaseModel):
    pfp: str | None
    name: str | None
    rating: float | None
    post_type: str | None
    desc: str | None
    joined: bool | None
    valid: bool
    errormsg: str | None

class ConfirmationResponse(BaseModel):
    valid: bool
    errormsg: str | None

class ConvoPreview(BaseModel):
    pfps: list[str | None]
    names: list[str]
    conversation_id: int

class PostContacts(BaseModel):
    contacts: list[ConvoPreview]
    valid: bool
    errormsg : str | None

class PostUsers(BaseModel):
    users: list[str]
    valid: bool
    errormsg: str | None

########################################
#             FUNCTIONS                #
########################################

'''
Load a specific post
'''
@router.get('/post', response_model=PostDetails)
async def load_post(token_header: str = Header(),
                    post_id_header: int = Header()):
    
    pfp = name = rating = desc = post_type = joined = None

    post = PostSpecification(token=token_header, post_id=post_id_header,
                             rating=None, search_username=None)

    # decode the user token
    user, valid, errormsg = decode_token(post.token)

    if valid:
        # grab the user's id
        cursor.execute('SELECT UserID FROM Users WHERE Username = ?', user)
        uid = cursor.fetchone()[0]

        # check if the user has already joined the post
        cursor.execute('SELECT UserID FROM UserPosts WHERE UserID = ? AND PostID = ?', 
                       (uid, post.post_id))
        in_post = cursor.fetchone()

        # joined status important for frontend to know if they need to
        # ask user if they want to join the class or if they should load
        # the messaging system
        joined = True if in_post else False

        # load the rest of the post: pfp of owner, name of owner,
        # rating, and description
        cursor.execute('SELECT ProfilePicURL, Username, Rating, Description, UserDesignation '
                       'FROM Posts AS p '
                            'JOIN Users AS u '
                                'ON p.OwnerUserID = u.UserID '
                            'JOIN UserCourses AS uc '
                                'ON p.OwnerCourseId = uc.CourseID AND '
                                    'u.UserID = uc.UserID '
                       'WHERE PostID = ?', (post.post_id,))
        post_tuple = cursor.fetchone()
        
        # parse out the different parts of the post
        pfp = post_tuple[0]
        name = post_tuple[1]
        rating = post_tuple[2]
        desc = post_tuple[3]
        post_type = 'Study Buddy' if post_tuple[4] == 'student' else 'Tutor'
        
    return {'pfp': pfp,
            'name': name,
            'rating': rating,
            'post_type': post_type,
            'desc': desc,
            'joined': joined,
            'valid': valid,
            'errormsg': errormsg}



'''
Allow a user to join a post group, this will link their
UserID to a PostID
'''
@router.post('/post/join', response_model=ConfirmationResponse)
async def add_user_to_post(post: PostSpecification):

    # decode the user token
    user, valid, errormsg = decode_token(post.token)

    if valid:
        # grab the user's id
        cursor.execute('SELECT UserID FROM Users WHERE Username = ?', user)
        uid = cursor.fetchone()[0]

        # add the user to the post group
        cursor.execute('INSERT INTO UserPosts VALUES (?, ?)', (uid, post.post_id))
        cursor.commit()

    return {'valid': valid,
            'errormsg': errormsg}



'''
Allow a user to create a rating for the post, this is
the rating of the tutor in the specific subject
'''
@router.post('/post/create-rating', response_model=ConfirmationResponse)
async def rate(post: PostSpecification):

    # decode the user token
    user, valid, errormsg = decode_token(post.token)

    if valid:
        # confirm the user is in the post group (as well as not the post owner) 
        # before they can rate
        cursor.execute('SELECT UserID FROM Users WHERE Username = ?', user)
        uid = cursor.fetchone()[0]

        cursor.execute('SELECT UserID ' 
                       'FROM UserPosts AS up '
                            'JOIN Posts AS p '
                                'ON up.PostID = p.PostID '
                       'WHERE UserID = ? AND up.PostID = ? AND UserID <> OwnerUserID',
                        (uid, post.post_id))
        in_postgroup = cursor.fetchone()

        if in_postgroup:
            # grab the current rating for the post
            cursor.execute('SELECT Rating, RatingsLeft FROM Posts WHERE PostID = ?', (post.post_id,))
            rating_info = cursor.fetchone()

            curr_rating = 0 if rating_info[0] is None else rating_info[0]

            # calculate the new rating
            new_ratings_left = rating_info[1] + 1
            new_rating = ((curr_rating * rating_info[1]) + post.rating) / new_ratings_left

            # update DB with new rating
            cursor.execute('UPDATE Posts SET Rating = ?, RatingsLeft = ? '
                           'WHERE PostID = ?', (new_rating, new_ratings_left, post.post_id))
            cursor.commit()
        else:
            valid = False
            errormsg = 'user does not belong to post group or is owner'

    return {'valid': valid,
            'errormsg': errormsg}



'''
Load a user's contacts for a specific post, it should
be noted that this contact list is for contacts where
a conversation has started already
'''
@router.get('/post/load-contacts', response_model=PostContacts)
async def load_contacts(token_header: str = Header(),
                        post_id_header: int = Header()):

    contacts = []

    post = PostSpecification(token=token_header, post_id=post_id_header,
                             rating=None, search_username=None)
    
    # decode the user token
    user, valid, errormsg = decode_token(post.token)

    if valid:
        # grab the user id
        cursor.execute('SELECT UserID FROM Users WHERE Username = ?', user)
        uid = cursor.fetchone()[0]

        # grab a preview for all conversations the user is involved in (for this post)
        # also called a contact since it includes pfp(s) and username(s)
        cursor.execute('SELECT ProfilePicURL, Username, uc.ConversationID '
                       'FROM UserConversations AS uc '
                            'JOIN Conversations AS c '
                                'ON uc.ConversationID = c.ConversationID '
                            'JOIN Users AS u '
                                'ON uc.UserID = u.UserID '
                       'WHERE PostID = ? AND uc.UserID <> ? AND '
                             'uc.ConversationID IN (SELECT ConversationID '
                                                   'FROM UserConversations '
                                                   'WHERE UserID = ?) '
                       'ORDER BY uc.ConversationID'
                        ,(post.post_id, uid, uid))
        rows = cursor.fetchall()

        # iterate through the returned rows, making a contact 
        # (conversation preview) for each conversation
        participants = []
        participants_pfps = []
        for i, row in enumerate(rows):
            participants.append(row[1])
            participants_pfps.append(row[0])
            # if last row or conversation id changes, make the contact
            if i == len(rows) - 1 or row[2] != rows[i + 1][2]:
                contacts.append({'pfps': participants_pfps,
                                 'names': participants,
                                 'conversation_id': row[2]})
                participants = []
                participants_pfps = []

    return {'contacts': contacts,
            'valid': valid,
            'errormsg': errormsg}



'''
Search users within the post, can optionally search with
username keywords
'''
@router.get('/post/search-users', response_model=PostUsers)
async def search_users(token_header: str = Header(),
                       post_id_header: int = Header(),
                       username_header: Optional[str] = Header(None)):
    
    users = []

    post = PostSpecification(token=token_header, post_id=post_id_header,
                             rating=None, search_username=username_header)

    # decode the user token
    user, valid, errormsg = decode_token(post.token)

    if valid:
        # grab the user's id
        cursor.execute('SELECT UserID FROM Users WHERE Username = ?', user)
        uid = cursor.fetchone()[0]

        # if using a search user keyword, format a sub-command
        if post.search_username:
            subcommand = ' AND Username LIKE ?'
            specs = (post.post_id, uid, '%' + post.search_username + '%')
        else:
            subcommand = ''
            specs = (post.post_id, uid)

        # search the DB for users in the post group 
        # (minus the user making the request)
        cursor.execute('SELECT Username '
                       'FROM UserPosts AS up '
                            'JOIN Users AS u '
                                'ON up.UserID = u.UserID '
                       'WHERE PostID = ? AND up.UserID <> ?' + subcommand, 
                       specs)
        users = cursor.fetchall()
        
        # format the returned rows into a list
        for i, user in enumerate(users):
            users[i] = user[0]

    return {'users': users,
            'valid': valid,
            'errormsg': errormsg}
