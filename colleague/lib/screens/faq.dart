import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color.fromARGB(0, 0, 0, 0),
        centerTitle: true,
        title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Image.asset(
              'images/logo.png',
              // Assuming you have a login image
              height: 40.0,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          const Text('FAQ',
              style: TextStyle(
                  color: Color.fromARGB(255, 92, 153, 245),
                  fontFamily: 'Baker',
                  fontSize: 40,
                  fontWeight: FontWeight.bold))
        ]),
      ),
      body: ListView(
        //padding: EdgeInsets.all(16.0),
        children: <Widget>[
          FAQItem(
            question: 'How do I reset my password?',
            answer:
                'To reset your password, go to the login screen and click on the "Forgot Password" link. Follow the instructions to reset your password.',
          ),
          const SizedBox(height: 16.0),
          FAQItem(
            question: 'How do I contact customer support?',
            answer:
                'You can contact our customer support team through the chat feature in the app. Simply tap on the chat icon and start a conversation with one of our agents.',
          ),
          const SizedBox(height: 16.0),
          FAQItem(
            question: 'Can I change my account settings?',
            answer:
                'Yes, you can change your account settings by navigating to the settings screen. From there, you can update your profile information, notification preferences, and more.',
          ),
          const SizedBox(height: 16.0),
          FAQItem(
            question: 'Is my personal information secure?',
            answer:
                'Yes, we take the security and privacy of your personal information very seriously. We use industry-standard encryption and security measures to protect your data.',
          ),
          const SizedBox(height: 16.0),
          FAQItem(
            question: 'How do I update the app?',
            answer:
                'To update the app, go to the app store on your device (e.g., Google Play Store or Apple App Store) and check for updates. If there is an update available, you can download and install it from there.',
          ),
          const SizedBox(height: 16.0),
          FAQItem(
            question: 'What do I do if I encounter an error?',
            answer:
                'If you encounter an error while using the app, please try restarting the app first. If the issue persists, you can contact our support team for assistance.',
          ),
          const SizedBox(height: 16.0),
          FAQItem(
            question: 'How do I change my notification settings?',
            answer:
                'You can change your notification settings by navigating to the settings screen in the app. From there, you can customize your notification preferences for various events and updates.',
          ),
          const SizedBox(height: 16.0),
          FAQItem(
            question: 'Can I use the app on multiple devices?',
            answer:
                'Yes, you can use the app on multiple devices as long as you log in with the same account credentials. Your data and settings will be synced across all your devices.',
          ),
          const SizedBox(height: 16.0),
          FAQItem(
            question: 'Do you offer support in multiple languages?',
            answer:
                'Yes, we offer support in multiple languages. You can change the app language preferences in the settings screen to access support in your preferred language.',
          ),
          const SizedBox(height: 16.0),
          FAQItem(
            question: 'How do I provide feedback about the app?',
            answer:
                'We welcome your feedback about the app! You can provide feedback by navigating to the settings screen and selecting the "Provide Feedback" option. Alternatively, you can contact our support team directly.',
          ),
          const SizedBox(height: 16.0),
          FAQItem(
            question: 'What do I do if I forget my username?',
            answer:
                'If you forget your username, you can recover it by clicking on the "Forgot Username" link on the login screen. Follow the instructions to retrieve your username.',
          ),
        ],
      ),
    );
  }
}

class FAQItem extends StatelessWidget {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [
        Color.fromARGB(255, 222, 224, 236),
        Color.fromARGB(255, 187, 195, 241)
      ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
        children: <Widget>[
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              answer,
              style: const TextStyle(fontSize: 14.0),
            ),
          ),
        ],
      ),
    );
  }
}
