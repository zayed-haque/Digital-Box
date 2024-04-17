import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ComplaintScreen extends StatefulWidget {
  @override
  _ComplaintScreenState createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = '';
  String _userId = 'default_user_id';

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _submitComplaint() async {
    if (_formKey.currentState!.validate()) {
      final complaintData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'category': _category,
        'user_id': _userId,
      };

      try {
        final apiUrl = dotenv.env['API_URL'];
        final response = await http.post(
          Uri.parse('$apiUrl/complaint'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(complaintData),
        );

        if (response.statusCode == 200) {
          _animationController.forward().then((_) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Success'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Complaint submitted successfully.'),
                      SizedBox(height: 16),
                      Text('Title: ${_titleController.text}'),
                      Text('Category: $_category'),
                    ],
                  ),
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
          });
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Error'),
                content:
                    Text('Failed to submit the complaint. Please try again.'),
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
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _category = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Raise a Complaint'),
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
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  value: _category.isNotEmpty ? _category : null,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      child: Text('Select a category'),
                      value: '',
                    ),
                    DropdownMenuItem(
                      child: Text('Account Opening'),
                      value: 'Account Opening',
                    ),
                    DropdownMenuItem(
                      child: Text('Debit Card'),
                      value: 'Debit Card',
                    ),
                    DropdownMenuItem(
                      child: Text('Credit Card'),
                      value: 'Credit Card',
                    ),
                    DropdownMenuItem(
                      child: Text('Loan'),
                      value: 'Loan',
                    ),
                    DropdownMenuItem(
                      child: Text('Internet Banking'),
                      value: 'Internet Banking',
                    ),
                    DropdownMenuItem(
                      child: Text('Mobile Banking'),
                      value: 'Mobile Banking',
                    ),
                    DropdownMenuItem(
                      child: Text('UPI'),
                      value: 'UPI',
                    ),
                    DropdownMenuItem(
                      child: Text('Transaction Dispute'),
                      value: 'Transaction Dispute',
                    ),
                    DropdownMenuItem(
                      child: Text('Other'),
                      value: 'Other',
                    ),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _category = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submitComplaint,
                  child: Text('Submit Complaint'),
                ),
                SizedBox(height: 24),
                Center(
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (BuildContext context, Widget? child) {
                      return Opacity(
                        opacity: _animation.value,
                        child: Icon(
                          Icons.check_circle,
                          size: 48,
                          color: Colors.green,
                        ),
                      );
                    },
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