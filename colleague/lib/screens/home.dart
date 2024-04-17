import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DocumentRequestScreen extends StatefulWidget {
  @override
  _DocumentRequestScreenState createState() => _DocumentRequestScreenState();
}

class _DocumentRequestScreenState extends State<DocumentRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _purposeController = TextEditingController();
  String _documentType = '';
  String _selectedDepartment = '';

  List<String> departments = [
    'Account Services',
    'Loans and Mortgages',
    'Credit Cards',
    'Wealth Management',
    'Business Banking',
    'Fraud Prevention',
    'Customer Support',
  ];

  void _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      String collegueId = await fetchCurrentUserId();
      final requestData = {
        'email': _emailController.text,
        'document_type': _documentType,
        'document_purpose': _purposeController.text,
        'collegue_id': collegueId,
        'requested_dpt': _selectedDepartment,
      };

      try {
        final apiUrl = dotenv.env['API_URL'];
        final response = await http.post(
          Uri.parse('$apiUrl/request-document'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestData),
        );

        if (response.statusCode == 200) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Success'),
                content: Text('Document request submitted successfully.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _clearForm();
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
                title: Text('Error'),
                content: Text(
                    'Failed to submit the document request. Please try again.'),
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
  }

  void _clearForm() {
    _emailController.clear();
    _purposeController.clear();
    setState(() {
      _documentType = '';
      _selectedDepartment = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Document'),
        centerTitle: true,
        backgroundColor: Colors.blue[900],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Customer Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter customer email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  value: _documentType.isNotEmpty ? _documentType : null,
                  decoration: InputDecoration(
                    labelText: 'Document Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    prefixIcon: Icon(Icons.description),
                  ),
                  items: [
                    DropdownMenuItem(child: Text('Select a type'), value: ''),
                    DropdownMenuItem(
                        child: Text('Aadhar Card'), value: 'Aadhar Card'),
                    DropdownMenuItem(
                        child: Text('Pan Card'), value: 'Pan Card'),
                    DropdownMenuItem(
                        child: Text('Passport'), value: 'Passport'),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a document type';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _documentType = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedDepartment.isNotEmpty ? _selectedDepartment : null,
                  decoration: InputDecoration(
                    labelText: 'Select Department',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    prefixIcon: Icon(Icons.business),
                  ),
                  items: departments.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a department';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartment = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _purposeController,
                  decoration: InputDecoration(
                    labelText: 'Document Purpose',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    prefixIcon: Icon(Icons.note),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter document purpose';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitRequest,
                  child: Text(
                    'Submit Request',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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