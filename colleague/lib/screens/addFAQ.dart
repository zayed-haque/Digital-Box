import 'package:flutter/material.dart';

class AddFAQScreen extends StatefulWidget {
  @override
  _AddFAQScreenState createState() => _AddFAQScreenState();
}

class _AddFAQScreenState extends State<AddFAQScreen> {
  TextEditingController _questionController = TextEditingController();
  TextEditingController _answerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var height = size.height;
    var width = size.width;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 171, 147, 147),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Image.asset(
                'images/logo.png',
                height: 40.0,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'FAQ SECTION',
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Baker',
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),


      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _questionController,
              decoration: InputDecoration(
                labelText: 'Question',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20.0),
            TextFormField(
              controller: _answerController,
              decoration: InputDecoration(
                labelText: 'Answer',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                _addFAQ();
              },
              child: Text('Add FAQ'),
            ),
          ],
        ),
      ),
    );
  }

  void _addFAQ() {
    String question = _questionController.text;
    String answer = _answerController.text;
    print('Question: $question');
    print('Answer: $answer');

    _questionController.clear();
    _answerController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('FAQ added successfully!'),
      ),
    );
  }
}
