import string
import random
from fastapi import APIRouter
from pydantic import BaseModel
from ..db_init import cursor
from .login import decode_token

router = APIRouter()

########################################
#           PYDANTIC MODELS            #
########################################

class AddConversationSpecification(BaseModel):
    token: str
    convo_partners: list[str]
    post_id: int

class ConvoCreationResponse(BaseModel):
    conversation_id: int | None
    valid: bool
    errormsg: str | None

class ConversationSpecification(BaseModel):
    conversation_id: int

class ConvoMessages(BaseModel):
    convo: list[dict[str, str]]

class MessageSpecification(BaseModel):
    token: str
    conversation_id: int
    message: str

class ConfirmationResponse(BaseModel):
    valid: bool
    errormsg: str | None

class MeetingResponse(BaseModel):
    meeting_link: str | None

########################################
#             FUNCTIONS                #
########################################

'''
Create and add a new conversation
'''
@router.post('/post/add-conversation', response_model=ConvoCreationResponse)
async def add_conversation(convo_spec: AddConversationSpecification):

    conversation_id = None

    # decode the user token
    user, valid, errormsg = decode_token(convo_spec.token)

    if valid:
        # grab the user's id
        cursor.execute('SELECT UserID FROM Users WHERE Username = ?', user)
        uid = cursor.fetchone()[0]

        # construct the query for grabbing the conversation participants' ids
        markers = ",".join(["?"] * len(convo_spec.convo_partners))
        query = 'SELECT UserID FROM Users WHERE Username IN (' + markers + ')'

        # grab the user ids of the other conversation participants
        cursor.execute(query,
                       convo_spec.convo_partners)
        participant_ids = cursor.fetchall()

        # combine all of the ids into one list
        ids = [uid]
        for i in participant_ids:
            ids.append(i[0])

        # create the conversation
        cursor.execute('INSERT INTO Conversations VALUES (?, ?)', (convo_spec.post_id ,None))
        cursor.commit()

        # grab the conversation id
        cursor.execute('SELECT ConversationID FROM Conversations AS c ' 
                       'WHERE NOT EXISTS (SELECT * FROM UserConversations AS uc '
                                         'WHERE c.ConversationID = uc.ConversationID)')
        conversation_id = cursor.fetchone()[0]

        # link the users to the conversation
        for id in ids:
            cursor.execute('INSERT INTO UserConversations VALUES (?, ?)',
                           (conversation_id, id))
            cursor.commit()

    return {'conversation_id': conversation_id,
            'valid': valid,
            'errormsg': errormsg}



'''
Load a conversation (conversation messages)
'''
@router.get('/post/load-conversation', response_model=ConvoMessages)
async def load_conversation(convo_spec: ConversationSpecification):
    
    convo = []

    # grab all the messages from the conversation
    cursor.execute('SELECT Username, Message '
                   'FROM Messages AS m '
                        'INNER JOIN Users AS u '
                            'ON m.SenderID = u.UserID '
                    'WHERE ConversationID = ? '
                    'ORDER BY ConversationID', (convo_spec.conversation_id,))
    
    # messages are returned in a username, message pair
    # index 0 is OLDEST message, index n is NEWEST message
    response = cursor.fetchall()

    # structure the conversation to return
    for pair in response:
        convo.append({'User': pair[0], 'Message': pair[1]})
    
    return {'convo': convo}



'''
Store a message sent by the user
'''
@router.post('/post/send-message', response_model=ConfirmationResponse)
async def store_message(msg_spec: MessageSpecification):
    
    # decode the user token
    user, valid, errormsg = decode_token(msg_spec.token)

    if valid:
        # grab the user's id
        cursor.execute('SELECT UserID FROM Users WHERE Username = ?', user)
        uid = cursor.fetchone()[0]

        # store the message
        cursor.execute('INSERT INTO Messages VALUES (?, ?, ?)', 
                       (msg_spec.conversation_id, uid, msg_spec.message))
        cursor.commit()

    return {'valid': valid,
            'errormsg': errormsg}



'''
Create a meeting for a conversation
'''
@router.post('/post/create-meeting', response_model=MeetingResponse)
async def create_meeting(convo_spec: ConversationSpecification):

    # create a random 40 character seed
    seed = ''.join(random.choices(string.ascii_letters + string.digits, k=40))

    # embed this seed in a jitsi link to make the meeting
    meeting_link = f"https://meet.jit.si/TutorFinder-{seed}"

    # link the meeting to the conversation that requested it
    cursor.execute('UPDATE Conversations SET MeetingLink = ? WHERE ConversationID = ?',
                   (meeting_link, convo_spec.conversation_id))
    cursor.commit()

    return {'meeting_link': meeting_link}



'''
Retrieve a meeting link for a previously created meeting
'''
@router.get('/post/load-meeting', response_model=MeetingResponse)
async def load_meeting(convo_spec: ConversationSpecification):

    # retrieve the meeting link from the database
    cursor.execute('SELECT MeetingLink FROM Conversations WHERE ConversationID = ?', 
                   (convo_spec.conversation_id,))
    meeting_link = cursor.fetchone()[0]

    return {'meeting_link': meeting_link}
