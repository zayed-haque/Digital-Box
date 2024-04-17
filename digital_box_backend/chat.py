from flask import Flask, jsonify, request
from flask_socketio import SocketIO, emit
from flask_cors import CORS
import boto3
import json
from datetime import datetime
import uuid
import base64
import os

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})
socketio = SocketIO(app, cors_allowed_origins="*")

s3 = boto3.client(
    "s3",
    aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
    aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
)
BUCKET_NAME = os.getenv("BUCKET_NAME")

dynamodb = boto3.resource(
    "dynamodb",
    region_name=os.getenv("AWS_REGION"),
    aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
    aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
)
chat_table = dynamodb.Table(os.getenv("CHAT_TABLE"))

@socketio.on('connect')
def handle_connect():
    print('Client connected')

@socketio.on('disconnect')
def handle_disconnect():
    print('Client disconnected')

@socketio.on('send_message')
def handle_send_message(data):
    message = json.loads(data)
    complaint_id = message['complaint_id']
    sender_id = message['sender_id']
    message_text = message['message']
    timestamp = datetime.now().isoformat()
    message_id = str(uuid.uuid4())

    attachment = message.get('attachment')
    attachment_url = None
    if attachment:
        attachment_name = attachment['name']
        attachment_bytes = base64.b64decode(attachment['bytes'])
        s3_key = f"attachments/{complaint_id}/{message_id}/{attachment_name}"
        s3.put_object(Body=attachment_bytes, Bucket=BUCKET_NAME, Key=s3_key)
        attachment_url = f"https://{bucket_name}.s3.amazonaws.com/{s3_key}"

    # Store the message in DynamoDB
    chat_table.put_item(
        Item={
            'complaint_id': complaint_id,
            'message_id': message_id,
            'sender_id': sender_id,
            'message': message_text,
            'timestamp': timestamp,
            'attachment_url': attachment_url
        }
    )

    # Emit the message to all connected clients
    emit('receive_message', data, broadcast=True)

@socketio.on('request_messages')
def handle_request_messages(complaint_id):
    print('Requesting messages for complaint ID:', complaint_id)
    # Retrieve all chat messages for the complaint from DynamoDB
    response = chat_table.query(
        IndexName='complaint_id-message_id-index',
        KeyConditionExpression='complaint_id = :complaint_id',
        ExpressionAttributeValues={':complaint_id': complaint_id},
        ScanIndexForward=True
    )
    messages = response['Items']
    # Emit the messages to the requesting client
    for message in messages:
        emit('receive_message', json.dumps({
            'complaint_id': message['complaint_id'],
            'sender_id': message['sender_id'],
            'message': message['message'],
            'timestamp': message['timestamp'],
            'attachment_url': message.get('attachment_url')
        }))

@app.route('/chat/<complaint_id>')
def get_chat_messages(complaint_id):
    # Retrieve all chat messages for a specific complaint from DynamoDB
    response = chat_table.query(
        IndexName='complaint_id-message_id-index',
        KeyConditionExpression='complaint_id = :complaint_id',
        ExpressionAttributeValues={':complaint_id': complaint_id},
        ScanIndexForward=True
    )
    messages = response['Items']
    return jsonify(messages)

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5001)