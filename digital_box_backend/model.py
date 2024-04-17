from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

class User(db.Model):
    id = db.Column(db.String(120), primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    complaints = db.relationship('Complaints', backref='user', lazy=True)

class Collegue(db.Model):
    id = db.Column(db.String(120), primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    document_requests = db.relationship('Documentrequest', backref='collegue', lazy=True)

class Complaints(db.Model):
    complaint_id = db.Column(db.String(120), primary_key=True)
    encrypted_data = db.Column(db.String(120), nullable=False)
    encryption_key = db.Column(db.String(120), nullable=False)
    user_id = db.Column(db.String(120), db.ForeignKey('user.id'), nullable=False)
    ticket = db.relationship('Ticket', backref='complaints',uselist=False, lazy=True)
    created_at = db.Column(db.String(100), nullable=False)

class Ticket(db.Model):
    ticket_id = db.Column(db.String(120), primary_key=True)
    ticket_status = db.Column(db.String(120), nullable=False)
    complaint_id = db.Column(db.String(120), db.ForeignKey('complaints.complaint_id'), nullable=False)
    user_id = db.Column(db.String(120), db.ForeignKey('user.id'), nullable=False)

class Document(db.Model):
    document_id = db.Column(db.String(120), primary_key=True)
    user_id = db.Column(db.String(120), db.ForeignKey('user.id'), nullable=False)
    document_type = db.Column(db.String(120), nullable=False)
    filename = db.Column(db.String(120), nullable=False)
    uploaded_at = db.Column(db.String(100), nullable=False)
    requested_colleague_id = db.Column(db.String(120), db.ForeignKey('collegue.id'), nullable=False)
    document_request_id = db.Column(db.String(120), db.ForeignKey('documentrequest.request_id'), nullable=False)
    presigned_url = db.Column(db.String(120), nullable=False)

class Documentrequest(db.Model):
    request_id = db.Column(db.String(120), primary_key=True)
    user_id = db.Column(db.String(120), db.ForeignKey('user.id'), nullable=False)
    document_type = db.Column(db.String(120), nullable=False)
    colleague_id = db.Column(db.String(120), db.ForeignKey('collegue.id'), nullable=False)
    requested_at = db.Column(db.String(100), nullable=False)
    document_purpose = db.Column(db.String(200), nullable=False)
    requested_dpt = db.Column(db.String(120), nullable=False)


