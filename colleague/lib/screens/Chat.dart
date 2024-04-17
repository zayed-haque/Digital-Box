import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatScreen extends StatefulWidget {
  final String complaintId;
  final String userId;
  final String ticketId;
  final String ticketStatus;

  ChatScreen({
    required this.complaintId,
    required this.userId,
    required this.ticketId,
    required this.ticketStatus,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late IO.Socket socket;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  String _summary = '';
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _buttonAnimation;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _connectToServer();
    _fetchPreviousMessages();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _buttonAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _downloadAttachment(String attachmentUrl) async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      final directory = await getExternalStorageDirectory();
      final localPath = '${directory!.path}/downloads';

      await Directory(localPath).create(recursive: true);

      final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      final taskId = await FlutterDownloader.enqueue(
        url: attachmentUrl,
        savedDir: localPath,
        fileName: filename,
        showNotification: true,
        openFileFromNotification: true,
      );

      FlutterDownloader.registerCallback((id, status, progress) {
      });
    } else {
      print('Storage permission denied');
    }
  }

  void _connectToServer() {
    socket = IO.io(dotenv.env['SOCKET_URL']!);
    socket.on('connect', (_) {
      print('Connected to server');
    });

    socket.on('receive_message', (data) {
      print('Received message: $data');
      Map<String, dynamic> message = json.decode(data);
      setState(() {
        _listKey.currentState?.insertItem(_messages.length, duration: Duration(milliseconds: 500));
        _messages.add(message);
      });
    });
  }

  void _generateSummary() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/summarize/${widget.complaintId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _summary = data['summary'];
          _isLoading = false;
        });
      } else {
        print('Failed to generate summary. Status code: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error generating summary: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _fetchPreviousMessages() {
    socket.emit('request_messages', widget.complaintId);
  }

  void _sendMessage() {
    String messageText = _messageController.text.trim();
    if (messageText.isNotEmpty) {
      Map<String, dynamic> message = {
        'complaint_id': widget.complaintId,
        'sender_id': widget.userId,
        'message': messageText,
        'timestamp': DateTime.now().toIso8601String(),
        'attachment': null,
      };
      socket.emit('send_message', json.encode(message));
      _messageController.clear();
    }
  }

  Future<void> _selectAttachment() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      PlatformFile file = result.files.first;
      String messageText = _messageController.text.trim();
      Map<String, dynamic> message = {
        'complaint_id': widget.complaintId,
        'sender_id': widget.userId,
        'message': messageText,
        'timestamp': DateTime.now().toIso8601String(),
        'attachment': {
          'name': file.name,
          'bytes': base64Encode(file.bytes!),
        },
      };
      socket.emit('send_message', json.encode(message));
      _messageController.clear();
    }
  }

  void _closeTicket() async {
    final bool confirmClose = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Ticket Closure'),
        content: Text('Are you sure you want to close this ticket?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Confirm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (confirmClose == true) {
      final response = await http.put(
        Uri.parse('${dotenv.env['API_URL']}/ticket/${widget.ticketId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'ticket_status': 'closed'}),
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pop();
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Failed to close ticket. Please try again.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildAttachment(Map<String, dynamic> message) {
    if (message['attachment_url'] != null) {
      String attachmentName = message['attachment']['name'];
      String attachmentUrl = message['attachment_url'];
      String fileExtension = attachmentName.split('.').last.toLowerCase();

      if (['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension)) {
        return Container(
          margin: EdgeInsets.only(top: 8.0),
          child: GestureDetector(
            onTap: () {
              _downloadAttachment(attachmentUrl);
            },
            child: Image.network(
              attachmentUrl,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
        );
      } else {
        return Container(
          margin: EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Icon(Icons.attachment),
              SizedBox(width: 4.0),
              GestureDetector(
                onTap: () {
                  _downloadAttachment(attachmentUrl);
                },
                child: Text(
                  attachmentName,
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        actions: [
          IconButton(
            icon: Icon(Icons.summarize),
            onPressed: _generateSummary,
            tooltip: 'Generate Summary',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complaint ID: ${widget.complaintId}',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
                Text(
                  'Ticket ID: ${widget.ticketId}',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.normal,
                    fontSize: 11,
                  ),
                ),
                Text(
                  'Ticket Status: ${widget.ticketStatus}',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Chat',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedList(
              key: _listKey,
              initialItemCount: _messages.length,
              itemBuilder: (context, index, animation) {
                Map<String, dynamic> message = _messages[index];
                bool isUserMessage = message['sender_id'] == widget.userId;
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: isUserMessage ? Offset(1, 0) : Offset(-1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  )),
                  child: Align(
                    alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isUserMessage ? Theme.of(context).primaryColor : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['message'],
                            style: TextStyle(
                              color: isUserMessage ? Colors.white : Colors.black,
                            ),
                          ),
                          _buildAttachment(message),
                          SizedBox(height: 4),
                          Text(
                            message['timestamp'],
                            style: TextStyle(
                              fontSize: 12,
                              color: isUserMessage ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Container(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          if (!_isLoading && _summary.isNotEmpty)
            Container(
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(_summary),
                ],
              ),
            ),
          if (widget.ticketStatus != 'closed')
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  ScaleTransition(
                    scale: _buttonAnimation,
                    child: IconButton(
                      icon: Icon(Icons.check_circle),
                      onPressed: () {
                        _animationController.forward().then((_) {
                          _animationController.reverse();
                        });
                        _closeTicket();
                      },
                      tooltip: 'Close Ticket',
                      color: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.attach_file),
                    onPressed: _selectAttachment,
                    tooltip: 'Add Attachment',
                  ),
                  ScaleTransition(
                    scale: _buttonAnimation,
                    child: IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        _animationController.forward().then((_) {
                          _animationController.reverse();
                        });
                        _sendMessage();
                      },
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    socket.disconnect();
    _animationController.dispose();
    super.dispose();
  }
}