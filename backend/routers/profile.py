from fastapi import APIRouter, Header, UploadFile, File
from pydantic import BaseModel
from ..db_init import cursor
import jwt
import os
import requests
import datetime

router = APIRouter()

########################################
#           PYDANTIC MODELS            #
########################################

class UserToken(BaseModel):
    token: str

class ProfileGetResponse(BaseModel):
    joindate: str | None
    username: str | None
    profilepicurl: str | None
    valid: bool
    errormsg: str | None

class ProfilePostResponse(BaseModel):
    picture_url: str | None
    valid: bool
    msg: str | None

class UserPicture(BaseModel):
    file: UploadFile

class UserChangePassword(BaseModel):
    password: str   

########################################
#             FUNCTIONS                #
########################################

'''
Decode a user token, check validity
'''
def decode_token(usertoken: UserToken):

    username = None
    validity = True
    errormsg = None

    try: 
        payload = jwt.decode(usertoken.token, 
                             os.environ['TF_TokenizerKeyDecoder'],
                             'RS256')
        username = payload['username']

        # check token expiration
        if (datetime.datetime.strptime(payload['expiration'], "%Y-%m-%dT%H:%M:%S.%f%z") 
            <= datetime.datetime.now(datetime.timezone.utc)):
            validity = False
            errormsg = 'expired token'

    except jwt.InvalidTokenError:
        validity = False
        errormsg = 'invalid token'
    
    return username, validity, errormsg

'''
 Frontend will send token in Authorization header, will prefix token with "Bearer "
 We extract token from decode_token -> retrieve info from database -> send back to frontend
'''
@router.get('/profile', response_model=ProfileGetResponse)
async def profile(usertoken: UserToken):

    # decode the token
    username, valid, errormsg = decode_token(usertoken)

    if valid:
        # Get info from database
        cursor.execute('SELECT JoinDate, ProfilePicURL '
                        'FROM Users '
                        'WHERE Username = ?', (username,))
        result = cursor.fetchone()
        JoinDate = result[0].strftime('%Y-%m-%d')
        ProfilePicURL = result[1]
        return {'joindate': JoinDate, 'username': username, "profilepicurl": ProfilePicURL,'valid': valid,'errormsg': None}
    
    else:
        return {'joindate': None, 'username': None, "profilepicurl": None,'valid': valid,'errormsg': errormsg}
        

'''
Change profile pic implementation
'''
@router.post('/profile', response_model=ProfilePostResponse)
async def changeProfilePic(usertoken: UserToken, userpicture: UserPicture = File(...)):
    
    username, valid, errormsg = decode_token(usertoken)
    
    if valid:
        # Get picture file from frontend -> upload to imgbb -> get url from imgbb -> store in database -> return valid
        # Using imgBB to store pictures, then storing URL in database
        imgbb_api_key = 'ee7b844382605115a87c6955d5c90ed0'
        url = 'https://api.imgbb.com/1/upload'

        # Wait for picture to be fully read & upload to imgbb using requests
        file = await userpicture.file.read()
        file_extension = userpicture.file.content_type.split("/")[-1]
        file_name = "{username}.{file_extension}".format(username=username, file_extension=file_extension)

        files = {
            "image": (file_name, file, file_extension)
        }
        send2imgbb = requests.post(url, files=files, params={"key": imgbb_api_key})

        if send2imgbb.json()["success"] is True:
            display_url = send2imgbb.json()["data"]["display_url"]
            cursor.execute('''UPDATE Users 
                        SET ProfilePicURL = ? 
                        WHERE Username = ?''', (display_url, username))
            cursor.commit()
            return {'picture_url': display_url, 'valid': valid, 'errormsg': None}
        else:
            valid = False
            errormsg = "unable to upload image"
            return {'picture_url': None, 'valid': valid, 'errormsg': errormsg}
    else:
        return {'picture_url': None, 'valid': valid, 'errormsg': errormsg}

    



    








        


    

        


