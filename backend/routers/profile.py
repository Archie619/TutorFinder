from fastapi import APIRouter, Header, UploadFile, File
from pydantic import BaseModel
from ..db_init import cursor
import jwt
import requests

router = APIRouter()
public_key = '''-----BEGIN PUBLIC KEY-----
                MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQChbmUhXy+uc7hxVdCpd3ybuwD+
                i2D831H2CoyWe3MyvDhYchBWB4CYLkDlldRUTzwj+H3DM106MfnKXnXYWLy+426k
                7Uydj/0i0ekL8ZpxmxjJi2eFAZ8NnFKSAf5TY2MAxOGia5AkLaTCEBWfCMjakLEk
                N+SzcnSlVCF0phJEuwIDAQAB
                -----END PUBLIC KEY-----'''
algorithm = 'RS256'

########################################
#           PYDANTIC MODELS            #
########################################

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
 Frontend will send token in Authorization header, will prefix token with "Bearer "
 We extract token from auth header -> decode -> retrieve info from database -> send back to frontend
'''
@router.get('/profile', response_model=ProfileGetResponse)
async def profile(Authorization: str = Header(None)):

    valid = True
    errormsg = None

    # If user is not logged in, do not let them access profile
    if not Authorization:
        valid = False
        errormsg = 'no token'
    else:
        # Split string w/ 'Bearer ' to just get token
        token = Authorization.split("Bearer ")[-1]
        # Decode token
        try: 
            decoded_token = jwt.decode(token, 
                                      public_key,
                                      algorithm)
            username = decoded_token['username']

        except jwt.ExpiredSignatureError:
            valid = False
            errormsg = 'expired token'
            return {'joindate': None, 'username': None, "profilepicurl": None,'valid': valid,'errormsg': errormsg}

        except jwt.InvalidTokenError:
            valid = False
            errormsg = 'invalid token'
            return {'joindate': None, 'username': None, "profilepicurl": None,'valid': valid,'errormsg': errormsg}

        # Get info from database
        cursor.execute('SELECT JoinDate, ProfilePicURL '
                        'FROM Users '
                        'WHERE Username = ?', (username))
        result = cursor.fetchone()
        JoinDate = result[0].strftime('%Y-%m-%d')
        ProfilePicURL = result[1]

        return {'joindate': JoinDate, 'username': username, "profilepicurl": ProfilePicURL,'valid': valid,'errormsg': errormsg}

'''
Change profile pic implementation
'''
@router.post('/profile', response_model=ProfilePostResponse)
async def changeProfilePic(userpicture: UserPicture = File(...), Authorization: str = Header(None)):
    
    valid = True
    msg = None

     # If user is not logged in, do not let them access profile
    if not Authorization:
        valid = False
        msg = 'no token'
    else:
        # Split string w/ 'Bearer ' to just get token
        token = Authorization.split("Bearer ")[-1]
        # Decode token
        try: 
            decoded_token = jwt.decode(token, 
                                      public_key,
                                      algorithm)
            username = decoded_token['username']

        except jwt.ExpiredSignatureError:
            valid = False
            msg = 'expired token'
            return {'picture_url': None, 'valid': valid, 'msg': msg}
        
        except jwt.InvalidTokenError:
            valid = False
            msg = 'invalid token'
            return {'picture_url': None, 'valid': valid, 'msg': msg}    
        
    # Get picture file from frontend -> upload to imgbb -> get url from imgbb -> store in database -> return valid
    # Using imgBB to store pictures, then storing URL in database
    imgbb_api_key = '067885a9ec078c7b684956d6cccf9715'
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
        return {'picture_url': display_url, 'valid': valid, 'msg': msg}
    else:
        valid = False
        msg = "unable to upload image"
        return {'picture_url': None, 'valid': valid, 'msg': msg}
    



    








        


    

        


