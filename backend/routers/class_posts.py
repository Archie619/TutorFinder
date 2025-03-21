from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()

########################################
#           PYDANTIC MODELS            #
########################################

class ClassSpecification(BaseModel):
    class_id: int

class PostPreview(BaseModel):
    pfp: str
    name: str
    rating: float | None

class ClassPosts(BaseModel):
    posts: list[PostPreview]

class PostSpecification(BaseModel):
    token: str
    post_description: str

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
async def load_class(class_spec: ClassSpecification):
    return {'posts':[]}



'''
Create a post within a specific class
'''
@router.post('/class/create-post', response_model=PostCreatedResponse)
async def create_post(post_spec: PostSpecification):
    return {'valid': False,
            'errormsg': 'nothing created yet....'}