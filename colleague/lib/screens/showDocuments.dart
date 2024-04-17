import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DocumentScreen extends StatefulWidget {
  @override
  _DocumentScreenState createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  List<Document> _documents = [];

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    try {
      String userId = await fetchCurrentUserId();
      final apiUrl = dotenv.env['API_URL'];
      final response = await http.get(
        Uri.parse('$apiUrl/upload-document/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> documentsData = json.decode(response.body);
        final documents =
        documentsData.map((data) => Document.fromJson(data)).toList();
        setState(() {
          _documents = documents;
        });
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text(
                  'Failed to fetch documents. Please try again later.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text(
                'Failed to connect to the server. Please check your internet connection.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _downloadDocument(Document document) async {
    try {
      final response = await http.get(Uri.parse(document.presignedUrl));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final fileName = document.filename;

        if (await Permission.storage.request().isGranted) {
          final directory = await getExternalStorageDirectory();
          final filePath = '${directory!.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(bytes);

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Success'),
                content: Text('Document downloaded successfully.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Permission Denied'),
                content: Text('Please grant storage permission to download the document.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Failed to download the document. Please try again later.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to download the document. Please check your internet connection.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Documents'),
        centerTitle: true,
        backgroundColor: Colors.blue[900],
      ),
      body: _documents.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _documents.length,
        itemBuilder: (context, index) {
          final document = _documents[index];
          return ListTile(
            title: Text(document.filename),
            subtitle: Text('Uploaded at: ${document.uploadedAt}'),
            trailing: IconButton(
              icon: Icon(Icons.download),
              onPressed: () {
                _downloadDocument(document);
              },
            ),
          );
        },
      ),
    );
  }
}

class Document {
  final String documentId;
  final String userId;
  final String documentType;
  final String filename;
  final String uploadedAt;
  final String requestedColleagueId;
  final String documentRequestId;
  final String presignedUrl;
  final String file;

  Document({
    required this.documentId,
    required this.userId,
    required this.documentType,
    required this.filename,
    required this.uploadedAt,
    required this.requestedColleagueId,
    required this.documentRequestId,
    required this.presignedUrl,
    required this.file,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      documentId: json['document_id'],
      userId: json['user_id'],
      documentType: json['document_type'],
      filename: json['filename'],
      uploadedAt: json['uploaded_at'],
      requestedColleagueId: json['requested_colleague_id'],
      documentRequestId: json['document_request_id'],
      presignedUrl: json['presigned_url'],
      file: json['file'],
    );
  }
}

Future<List<AuthUserAttribute>> fetchCurrentUserAttributes() async {
  try {
    final result = await Amplify.Auth.fetchUserAttributes();
    return result;
  } on AuthException catch (e) {
    print('Error fetching user attributes: ${e.message}');
    return [];
  }
}

Future<String> fetchCurrentUserId() async {
  try {
    final attributes = await fetchCurrentUserAttributes();
    for (var attribute in attributes) {
      if (attribute.userAttributeKey == 'sub') {
        return attribute.value;
      }
    }
    return '';
  } catch (e) {
    print('Error fetching user ID: $e');
    return '';
  }
}