from fastapi import APIRouter, Header
from pydantic import BaseModel
from ..db_init import cursor
from .login import decode_token

router = APIRouter()

########################################
#           PYDANTIC MODELS            #
########################################

class OneClass(BaseModel):
    class_id: int

class PostPreview(BaseModel):
    post_id: int
    pfp: str | None
    name: str
    rating: float | None
    post_type: str

class ClassPosts(BaseModel):
    posts: list[PostPreview]

class PostSpecification(BaseModel):
    token: str
    class_id: int
    post_description: str | None

class PostCreatedResponse(BaseModel):
    valid: bool
    errormsg: str | None

########################################
#             FUNCTIONS                #
########################################

'''
Load a specific class
'''
@router.get('/class', response_model=ClassPosts)
async def load_class(class_header: int = Header()):

    posts = []

    class_spec = OneClass(class_id=class_header)

    # grab posts tied to the class, don't need to grab all information
    # related to post, just enough to make a preview
    cursor.execute('SELECT PostID, ProfilePicURL, Username, Rating, UserDesignation '
                   'FROM Posts AS p '
                        'INNER JOIN Users AS u '
                            'ON p.OwnerUserID = u.UserID '
                        'INNER JOIN UserCourses AS uc '
                            'ON p.OwnerCourseID = uc.CourseID AND '
                                'u.UserID = uc.UserID '
                    'WHERE OwnerCourseID = ?', class_spec.class_id)
    posts = cursor.fetchall()

    # format post previews
    for i, post in enumerate(posts):
        posts[i] = PostPreview(post_id = post[0],
                               pfp = post[1],
                               name = post[2],
                               rating = post[3],
                               post_type = 'Study Buddy' if post[4] == 'student' else 'Tutor')

    return {'posts': posts}



'''
Create a post within a specific class
'''
@router.post('/class/create-post', response_model=PostCreatedResponse)
async def create_post(post_spec: PostSpecification):

    # decode the user token
    user, valid, errormsg = decode_token(post_spec.token)

    if valid:
        # grab the user's id
        cursor.execute('SELECT UserID FROM Users WHERE Username = ?', user)
        uid = cursor.fetchone()[0]

        # create the new post
        cursor.execute('INSERT INTO Posts '
                       'VALUES (?, ?, NULL, ?, 0)',
                       (uid, post_spec.class_id, 
                        post_spec.post_description))
        cursor.commit()

    return {'valid': valid,
            'errormsg': errormsg}
