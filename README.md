# Digital-Box

A platform for managing internal support requests, document exchange, and communication between users and support colleagues. This system facilitates complaint resolution, document management, and provides analytics for internal processes.

## Table of Contents

- [Features](#features)
- [Technology Stack](#technology-stack)
- [Backend Setup](#backend-setup)
- [Frontend Setup](#frontend-setup)
- [API Endpoints](#api-endpoints)
- [Contributing](#contributing)
- [License](#license)

## Features

- **User and Colleague Authentication:** Secure login and registration for users and colleagues.
- **Complaint Management:** Users can submit complaints, view their status, and track them using a ticket-based system.
- **Document Request System:** Enables users to request specific documents from colleagues.
- **Secure Document Upload & Retrieval:** Colleagues can upload requested documents, which are stored securely on AWS S3 and can be retrieved by users.
- **Real-time Chat:** Facilitates communication between users and support, with an AI-powered chat summarization feature using OpenAI and Langchain.
- **Complaint Analytics:** Provides insights into complaint trends, including weekly statistics and domain-specific breakdowns.
- **Data Encryption:** Sensitive complaint data is encrypted to ensure privacy and security.

## Technology Stack

### Backend
- **Programming Language:** Python
- **Framework:** Flask, Flask-RESTful
- **ORM:** SQLAlchemy
- **Database:** PostgreSQL (or your configured SQL database)
- **AWS SDK:** Boto3 (for S3 and DynamoDB interaction)
- **AI/ML:** Langchain, OpenAI API
- **Environment Management:** python-dotenv

### Frontend
- **Programming Language:** Dart
- **Framework:** Flutter
- **Backend Integration:** Amplify Flutter, http
- **State Management/UI:** (Details can be added if known, e.g., Provider, Bloc)

### Databases Used
- **Primary Data:** PostgreSQL (or your configured SQL database for user, complaint, document metadata)
- **Chat Messages:** AWS DynamoDB

### Cloud Services
- **File Storage:** AWS S3

## Backend Setup

1.  **Clone the repository:**
    ```bash
    git clone <repository_url>
    cd Digital-Box/backend
    ```

2.  **Create and activate a virtual environment:**
    ```bash
    python3 -m venv venv
    source venv/bin/activate  # On Windows use `venv\Scripts\activate`
    ```

3.  **Install dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

4.  **Set up environment variables:**
    *   Copy the example environment file:
        ```bash
        cp .env.example .env
        ```
    *   Edit the `.env` file and provide the necessary values for:
        *   `AWS_ACCESS_KEY_ID`: Your AWS Access Key ID.
        *   `AWS_SECRET_ACCESS_KEY`: Your AWS Secret Access Key.
        *   `AWS_REGION`: The AWS region for your services (e.g., `us-east-1`).
        *   `BUCKET_NAME`: Name of the AWS S3 bucket for storing documents.
        *   `CHAT_TABLE`: Name of the AWS DynamoDB table for chat messages.
        *   `OPENAI_API_KEY`: Your API key for OpenAI services.
        *   `DATABASE_URL`: The connection string for your PostgreSQL database (e.g., `postgresql://user:password@host:port/database_name`). Ensure the database and schema are set up.
        *   `FLASK_APP`: Set to `api.py` (or your main Flask application file).
        *   `FLASK_ENV`: Set to `development` for development mode.


5.  **Initialize the database (if applicable):**
    *   If you have database migrations (e.g., using Flask-Migrate), run the migration commands.
    *   For initial schema creation, you might need to run a script or use `db.create_all()` from within a Python shell with the app context if not handled automatically. The `upload_initial_data.py` script might be relevant here for populating initial data or creating schema.
    ```python
    # Example for creating tables if not using migrations (run in Flask shell or a script)
    # from api import app, db
    # with app.app_context():
    #     db.create_all()
    ```
    *   You can also run the `upload_initial_data.py` script to populate the database with initial data after setting up the schema:
    ```bash
    python upload_initial_data.py
    ```


6.  **Run the backend server:**
    ```bash
    flask run
    ```
    Or, if not using `flask run`:
    ```bash
    python api.py
    ```
    The API should now be running on `http://127.0.0.1:5000/` (or the configured port).

## Frontend Setup

1.  **Ensure Flutter SDK is installed:**
    *   Follow the official Flutter installation guide: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)

2.  **Navigate to the frontend directory:**
    ```bash
    cd ../colleague  # Assuming you are in the 'backend' directory, otherwise navigate to Digital-Box/colleague
    ```

3.  **Set up environment variables for the frontend:**
    *   Copy the example environment file:
        ```bash
        cp .env.example .env
        ```
    *   Edit the `.env` file and provide the necessary values. This typically includes:
        *   `BASE_URL`: The URL of your running backend API (e.g., `http://127.0.0.1:5000`).
        *   *(Add any other variables present in `colleague/.env.example`)*

4.  **Install Flutter dependencies:**
    ```bash
    flutter pub get
    ```

5.  **Configure AWS Amplify:**
    *   Ensure you have the Amplify CLI installed and configured. If not, follow the Amplify documentation: [https://docs.amplify.aws/cli/start/install/](https://docs.amplify.aws/cli/start/install/)
    *   Initialize Amplify in the project (if not already done by a previous developer):
        ```bash
        amplify init
        ```
    *   If backend resources are already defined and you need to pull the configuration:
        ```bash
        amplify pull
        ```
    *   The `amplify_outputs.dart` or similar configuration file should be generated/updated. This file is usually gitignored but is crucial for the app to connect to Amplify backend services.

6.  **Run the Flutter application:**
    *   Ensure you have an emulator running or a device connected.
    *   ```bash
        flutter run
        ```

    This will launch the Colleague application.

## API Endpoints

This section provides a quick overview of the main API endpoints. Refer to `backend/api.py` for detailed request/response formats and parameters.

-   **Encryption/Decryption:**
    -   `POST /encrypt`: Encrypts a given message.
    -   `PUT /decrypt`: Decrypts a given message using a key.
-   **Chat Summary:**
    -   `GET /summarize/<string:complaint_id>`: Summarizes chat messages related to a complaint.
-   **Analytics:**
    -   `GET /analytics`: Retrieves complaint analytics (e.g., weekly trends, domain percentages).
-   **User Management:**
    -   `POST /user`: Creates a new user.
    -   `GET /user/<string:user_id>`: Retrieves user details and their complaints.
-   **Complaint Management:**
    -   `POST /complaint`: Creates a new complaint and an associated ticket.
    -   `GET /complaint/<string:complaint_id>`: Retrieves details of a specific complaint.
    -   `GET /complaints`: Retrieves all open complaints.
-   **Ticket Management:**
    -   `GET /ticket/<string:ticket_id>`: Retrieves ticket status and details.
    -   `PUT /ticket/<string:ticket_id>`: Updates the status of a ticket (e.g., to resolved).
-   **Colleague Management:**
    -   `POST /collegue`: Creates a new colleague profile.
    -   `GET /collegue/<string:collegue_id>`: Retrieves colleague details and their assigned document requests.
-   **Document Requests:**
    -   `POST /request-document`: Allows a user to request a document.
    -   `GET /document-requests/<string:user_id>`: Retrieves pending document requests for a user.
-   **Document Uploads:**
    -   `POST /upload-document`: Allows a colleague to upload a document for a request (uploads to S3).
    -   `GET /upload-document/<string:id>`: Retrieves documents uploaded by/for a colleague.

## Contributing

Contributions are welcome! If you'd like to contribute to Digital-Box, please follow these general guidelines:

1.  **Fork the repository.**
2.  **Create a new branch** for your feature or bug fix:
    ```bash
    git checkout -b feature/your-feature-name
    ```
    or
    ```bash
    git checkout -b fix/your-bug-fix
    ```
3.  **Make your changes.** Ensure your code follows the project's coding style (if specified).
4.  **Write tests** for your changes, if applicable.
5.  **Commit your changes** with a clear and descriptive commit message.
6.  **Push your branch** to your forked repository.
7.  **Open a pull request** to the main Digital-Box repository.

Please provide a detailed description of your changes in the pull request.

*(Further details on code style, specific areas to contribute, or contact information can be added here later.)*

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
