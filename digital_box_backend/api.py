import datetime
import json
import os
import uuid
from collections import defaultdict

import boto3
from boto3.dynamodb.conditions import Key
from botocore.exceptions import ClientError
from cryptography.fernet import Fernet
from dotenv import load_dotenv
from flask import Flask, jsonify, make_response, request
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from langchain import OpenAI
from langchain.chains.summarize import load_summarize_chain
from langchain.docstore.document import Document as docstore_Document

from model import Collegue, Complaints, Document, Documentrequest, Ticket, User, db

load_dotenv()

app = Flask(__name__)
api = Api(app)

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

openai_api_key = os.getenv("OPENAI_API_KEY")
llm = OpenAI(openai_api_key=openai_api_key)
summarize_chain = load_summarize_chain(llm, chain_type="map_reduce")

KEY = Fernet.generate_key()
CIPHER_SUITE = Fernet(KEY)

# ==============================output fields========================================
complaint_fields = {
    "complaint_id": fields.String,
    "encrypted_data": fields.String,
    "encryption_key": fields.String,
    "user_id": fields.Integer,
}

ticket_fields = {
    "ticket_id": fields.String,
    "ticket_status": fields.String,
    "complaint_id": fields.Integer,
    "user_id": fields.Integer,
}

# ====================Create user, complaint, ticket request parsers=======================================
create_user_parser = reqparse.RequestParser()
create_user_parser.add_argument(
    "user_id", type=str, required=True, help="User id is required"
)
create_user_parser.add_argument(
    "email", type=str, required=True, help="Email is required"
)

create_collague_parser = reqparse.RequestParser()
create_collague_parser.add_argument(
    "collegue_id", type=str, required=True, help="Collegue id is required"
)
create_collague_parser.add_argument(
    "email", type=str, required=True, help="Email is required"
)

create_document_parser = reqparse.RequestParser()
create_document_parser.add_argument(
    "email", type=str, required=True, help="User Email is required"
)
create_document_parser.add_argument(
    "document_type", type=str, required=True, help="Document type is required"
)
create_document_parser.add_argument(
    "collegue_id", type=str, required=True, help="Collegue id is required"
)
create_document_parser.add_argument(
    "document_purpose", type=str, required=True, help="Document purpose is required"
)
create_document_parser.add_argument(
    "requested_dpt", type=str, required=True, help="Requested department is required"
)

create_complaint_parser = reqparse.RequestParser()
create_complaint_parser.add_argument(
    "title", type=str, required=True, help="title is required"
)
create_complaint_parser.add_argument(
    "description", type=str, required=True, help="description is required"
)
create_complaint_parser.add_argument(
    "category", type=str, required=True, help="category is required"
)
create_complaint_parser.add_argument(
    "user_id", type=str, required=True, help="User id is required"
)

update_ticket_parser = reqparse.RequestParser()
update_ticket_parser.add_argument(
    "ticket_status", type=str, required=True, help="Ticket status is required"
)

# ==============================Resource classes========================================


def generate_unique_complaint_id():
    timestamp = str(int(datetime.datetime.now().timestamp()))
    random_chars = uuid.uuid4().hex[:8]
    complaint_id = f"{timestamp}_{random_chars}"
    return complaint_id


def generate_ticket_id(complaint_id, user_id):
    ticket_id = f"{complaint_id}_{user_id}"
    return ticket_id


class EncryptionResource(Resource):
    def post(self):
        data = request.get_json()
        message = data.get("message")
        key = Fernet.generate_key()
        cipher_suite = Fernet(key)
        encrypted_message = cipher_suite.encrypt(message.encode()).decode()
        return {"encrypted_message": encrypted_message, "key": key.decode()}

    def put(self):
        data = request.get_json()
        encrypted_message = data.get("encrypted_message")
        key = data.get("key")
        cipher_suite = Fernet(key.encode())
        decrypted_message = cipher_suite.decrypt(encrypted_message.encode()).decode()
        return {"decrypted_message": decrypted_message}


class UserResource(Resource):
    def post(self):
        args = create_user_parser.parse_args()
        email = args.get("email")
        user_id = args.get("user_id")
        user = User.query.filter_by(email=email).first()
        if user:
            return make_response(jsonify({"message": "User already exists"}), 200)
        user = User(id=user_id, email=email)
        db.session.add(user)
        db.session.commit()
        return make_response(jsonify({"message": "User created successfully"}), 200)

    def get(self, user_id):
        user = User.query.filter_by(id=user_id).first()
        if not user:
            return make_response(jsonify({"message": "User not found"}), 404)
        complaints = Complaints.query.filter_by(user_id=user_id).all()
        complaints = sorted(complaints, key=lambda x: x.created_at, reverse=True)
        return make_response(
            jsonify(
                [
                    {
                        "complaint_id": complaint.complaint_id,
                        "complaint_data": json.loads(
                            CIPHER_SUITE.decrypt(
                                complaint.encrypted_data.encode()
                            ).decode()
                        ),
                        "user_id": complaint.user_id,
                        "created_at": complaint.created_at.isoformat(),
                        "ticketID": complaint.ticket.ticket_id,
                        "ticket_status": complaint.ticket.ticket_status,
                    }
                    for complaint in complaints
                ]
            ),
            200,
        )


class CollegueResource(Resource):
    def post(self):
        args = create_collague_parser.parse_args()
        email = args.get("email")
        collegue_id = args.get("collegue_id")
        collegue = Collegue.query.filter_by(email=email).first()
        if collegue:
            return make_response(jsonify({"message": "Collegue already exists"}), 200)
        collegue = Collegue(id=collegue_id, email=email)
        db.session.add(collegue)
        db.session.commit()
        return make_response(jsonify({"message": "Collegue created successfully"}), 200)

    def get(self, collegue_id):
        collegue = Collegue.query.filter_by(id=collegue_id).first()
        if not collegue:
            return make_response(jsonify({"message": "Collegue not found"}), 404)
        document_requests = Documentrequest.query.filter_by(
            collegue_id=collegue_id
        ).all()
        return make_response(
            jsonify(
                [
                    {
                        "request_id": document_request.request_id,
                        "user_id": document_request.user_id,
                        "document_type": document_request.document_type,
                        "requested_at": document_request.requested_at.isoformat(),
                    }
                    for document_request in document_requests
                ]
            ),
            200,
        )


class ComplaintResource(Resource):
    def post(self):
        args = create_complaint_parser.parse_args()
        data = json.dumps(args)
        encrypted_data = CIPHER_SUITE.encrypt(data.encode()).decode()
        complaint_id = generate_unique_complaint_id()
        user_id = args.get("user_id")
        created_at = datetime.datetime.now()
        complaint = Complaints(
            complaint_id=complaint_id,
            encrypted_data=encrypted_data,
            user_id=user_id,
            created_at=created_at,
        )
        db.session.add(complaint)
        db.session.commit()
        ticket_id = generate_ticket_id(complaint_id, user_id)
        ticket = Ticket(
            ticket_id=ticket_id,
            ticket_status="open",
            complaint_id=complaint_id,
            user_id=user_id,
        )
        db.session.add(ticket)
        db.session.commit()
        return make_response(jsonify({"message": "Complaint created successfully"}), 200)

    def get(self, complaint_id):
        complaint = Complaints.query.filter_by(complaint_id=complaint_id).first()
        if not complaint:
            return make_response(jsonify({"message": "Complaint not found"}), 404)
        decrypted_data = CIPHER_SUITE.decrypt(complaint.encrypted_data.encode()).decode()
        complaint_data = json.loads(decrypted_data)
        return make_response(
            jsonify(
                {
                    "complaint_id": complaint.complaint_id,
                    "complaint_data": complaint_data,
                    "user_id": complaint.user_id,
                    "created_at": complaint.created_at.isoformat(),
                }
            ),
            200,
        )


class TicketResource(Resource):
    def get(self, ticket_id):
        ticket = Ticket.query.filter_by(ticket_id=ticket_id).first()
        if not ticket:
            return make_response(jsonify({"message": "Ticket not found"}), 404)
        return make_response(
            jsonify(
                {"ticket_id": ticket.ticket_id, "ticket_status": ticket.ticket_status}
            ),
            200,
        )

    def put(self, ticket_id):
        ticket = Ticket.query.filter_by(ticket_id=ticket_id).first()
        if not ticket:
            return make_response(jsonify({"message": "Ticket not found"}), 404)
        args = update_ticket_parser.parse_args()
        ticket_status = args.get("ticket_status")
        if ticket_status:
            ticket.ticket_status = ticket_status
        db.session.commit()
        return make_response(jsonify({"message": "Ticket resolved successfully"}), 200)


class UserDocumentsResource(Resource):
    def get(self, user_id):
        req_documents = Documentrequest.query.filter_by(user_id=user_id).all()
        req_documents = [
            req_document
            for req_document in req_documents
            if not Document.query.filter_by(
                document_request_id=req_document.request_id
            ).first()
        ]
        return make_response(
            jsonify(
                [
                    {
                        "request_id": document_request.request_id,
                        "user_id": document_request.user_id,
                        "document_type": document_request.document_type,
                        "requested_at": document_request.requested_at.isoformat(),
                        "colleague_id": document_request.colleague_id,
                        "document_purpose": document_request.document_purpose,
                        "requested_dpt": document_request.requested_dpt,
                    }
                    for document_request in req_documents
                ]
            ),
            200,
        )

    def post(self):
        args = create_document_parser.parse_args()
        user_email = args.get("email")
        user = User.query.filter_by(email=user_email).first()
        if not user:
            return make_response(jsonify({"message": "User not found"}), 404)
        user_id = user.id
        document_type = args.get("document_type")
        collegue_id = args.get("collegue_id")
        document_purpose = args.get("document_purpose")
        requested_dpt = args.get("requested_dpt")
        requested_at = datetime.datetime.now()
        request_id = str(uuid.uuid4())
        document_request = Documentrequest(
            request_id=request_id,
            user_id=user_id,
            document_type=document_type,
            colleague_id=collegue_id,
            requested_at=requested_at,
            document_purpose=document_purpose,
            requested_dpt=requested_dpt,
        )
        db.session.add(document_request)
        db.session.commit()
        return make_response(
            jsonify({"message": "Document request created successfully"}), 200
        )


class UserUpladDocumentsResource(Resource):
    def post(self):
        if "file" not in request.files:
            return {"error": "No file uploaded"}, 400
        file = request.files["file"]
        filename = file.filename
        user_id = request.form.get("user_id")
        document_type = request.form.get("document_type")
        requested_colleague_id = request.form.get("colleague_id")
        document_request_id = request.form.get("request_id")
        uploaded_at = datetime.datetime.now()
        file_type = file.content_type
        if file_type not in ["application/pdf", "image/jpeg", "image/png"]:
            return {"error": "Invalid file type"}, 400
        try:
            s3.upload_fileobj(file, BUCKET_NAME, filename)
            presigned_url = s3.generate_presigned_url(
                "get_object", Params={"Bucket": BUCKET_NAME, "Key": filename}
            )
        except ClientError:
            return {"error": "Failed to upload file to S3"}, 500
        document_id = str(uuid.uuid4())
        document = Document(
            document_id=document_id,
            user_id=user_id,
            document_type=document_type,
            filename=filename,
            uploaded_at=uploaded_at,
            requested_colleague_id=requested_colleague_id,
            document_request_id=document_request_id,
            presigned_url=presigned_url,
        )
        db.session.add(document)
        db.session.commit()
        return {"message": "File uploaded successfully"}, 200

    def get(self, id):
        documents = Document.query.filter_by(requested_colleague_id=id).all()
        documents_data = [
            {
                "document_id": document.document_id,
                "user_id": document.user_id,
                "document_type": document.document_type,
                "filename": document.filename,
                "uploaded_at": document.uploaded_at.isoformat(),
                "requested_colleague_id": document.requested_colleague_id,
                "document_request_id": document.document_request_id,
                "presigned_url": document.presigned_url,
            }
            for document in documents
        ]
        return documents_data, 200


class AllComplaints(Resource):
    def get(self):
        complaints = Complaints.query.all()
        complaints = [
            complaint
            for complaint in complaints
            if complaint.ticket.ticket_status == "open"
        ]
        complaints = sorted(complaints, key=lambda x: x.created_at, reverse=True)
        return make_response(
            jsonify(
                [
                    {
"complaint_id": complaint.complaint_id,
                        "complaint_data": json.loads(
                            CIPHER_SUITE.decrypt(
                                complaint.encrypted_data.encode()
                            ).decode()
                        ),
                        "user_id": complaint.user_id,
                        "created_at": complaint.created_at.isoformat(),
                        "ticketID": complaint.ticket.ticket_id,
                        "ticket_status": complaint.ticket.ticket_status,
                    }
                    for complaint in complaints
                ]
            ),
            200,
        )


dynamodb = boto3.resource(
    "dynamodb",
    region_name=os.getenv("AWS_REGION"),
    aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
    aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
)
chat_table = dynamodb.Table(os.getenv("CHAT_TABLE"))

openai_api_key = os.getenv("OPENAI_API_KEY")
llm = OpenAI(openai_api_key=openai_api_key)
summarize_chain = load_summarize_chain(llm, chain_type="map_reduce")


class ChatSummaryResource(Resource):
    def get(self, complaint_id):
        response = chat_table.query(
            IndexName="complaint_id-message_id-index",
            KeyConditionExpression=Key("complaint_id").eq(complaint_id),
            ScanIndexForward=True,
        )
        messages = response["Items"]
        message_texts = [message["message"] for message in messages]
        documents = [docstore_Document(page_content=text) for text in message_texts]
        summary = summarize_chain.run(documents)
        return {"summary": summary}, 200


class ComplaintsAnalytics(Resource):
    def get(self):
        complaints = db.session.query(Complaints, Ticket).filter(
            Complaints.complaint_id == Ticket.complaint_id
        ).all()
        complaints_last_week = [
            complaint
            for complaint, ticket in complaints
            if ticket.ticket_status == "open"
            and datetime.datetime.fromisoformat(complaint.created_at)
            >= (datetime.datetime.now() - datetime.timedelta(days=7))
        ]
        queries_last_week = defaultdict(int)
        for complaint in complaints_last_week:
            day_of_week = datetime.datetime.fromisoformat(
                complaint.created_at
            ).strftime("%a")
            queries_last_week[day_of_week] += 1
        complaint_domains = defaultdict(int)
        total_complaints = len(complaints_last_week)
        for complaint in complaints_last_week:
            complaint_data = json.loads(
                CIPHER_SUITE.decrypt(complaint.encrypted_data.encode()).decode()
            )
            complaint_domain = complaint_data["category"]
            complaint_domains[complaint_domain] += 1
        complaint_domain_percentages = {
            domain: count / total_complaints for domain, count in complaint_domains.items()
        }
        return make_response(
            jsonify(
                {
                    "complaints_last_week": queries_last_week,
                    "complaint_domain_percentages": complaint_domain_percentages,
                }
            ),
            200,
        )


api.add_resource(EncryptionResource, "/encrypt", "/decrypt")
api.add_resource(ChatSummaryResource, "/summarize/<string:complaint_id>")
api.add_resource(ComplaintsAnalytics, "/analytics")
api.add_resource(UserResource, "/user", "/user/<string:user_id>")
api.add_resource(ComplaintResource, "/complaint", "/complaint/<string:complaint_id>")
api.add_resource(TicketResource, "/ticket/<string:ticket_id>")
api.add_resource(CollegueResource, "/collegue", "/collegue/<string:collegue_id>")
api.add_resource(
    UserDocumentsResource, "/request-document", "/document-requests/<string:user_id>"
)
api.add_resource(
    UserUpladDocumentsResource, "/upload-document", "/upload-document/<string:id>"
)
api.add_resource(AllComplaints, "/complaints")


if __name__ == "__main__":
    app.run()