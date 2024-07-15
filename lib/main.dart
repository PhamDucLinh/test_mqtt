import 'package:flutter/material.dart';
import 'mqtt_client.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng nhập MQTT'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isPasswordVisible,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String username = _usernameController.text;
                String password = _passwordController.text;

                if (username.isNotEmpty && password.isNotEmpty) {
                  bool success = await MQTTClientWrapper.connect(username, password);
                  if (success) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HomePage()),
                    );
                  } else {
                    // Hiển thị thông báo lỗi
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Đăng nhập thất bại'),
                        content: Text('Vui lòng kiểm tra lại username và password của bạn.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                } else {
                  // Hiển thị thông báo lỗi
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Thông tin không hợp lệ'),
                      content: Text('Vui lòng nhập username và password.'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: Text('Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool isConnected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MQTT Client Example'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _topicController,
              decoration: InputDecoration(labelText: 'Topic'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(labelText: 'Message'),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  MQTTClientWrapper.subscribe(_topicController.text);
                },
                child: Text('Subscribe'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  MQTTClientWrapper.publish(_topicController.text, _messageController.text);
                },
                child: Text('Publish'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  MQTTClientWrapper.disconnect();
                  setState(() {
                    isConnected = false;
                  });
                },
                child: Text('Disconnect'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () async {
                  bool success = await MQTTClientWrapper.reconnect();
                  if (success) {
                    setState(() {
                      isConnected = true;
                    });
                  } else {
                    // Hiển thị thông báo lỗi
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Reconnect thất bại'),
                        content: Text('Vui lòng thử lại.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: Text('Reconnect'),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<Map<String, dynamic>>(
              stream: MQTTClientWrapper.messageStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                } else if (!snapshot.hasData) {
                  return Center(child: Text('Chưa có tin nhắn nào'));
                } else {
                  final data = snapshot.data!;
                  return Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Relay: ${jsonEncode(data['relay'])}'),
                          Text('Switch: ${jsonEncode(data['sw'])}'),
                          Text('Fan: ${jsonEncode(data['fan'])}'),
                          Text('LED: ${jsonEncode(data['led'])}'),
                          Text('Battery: ${jsonEncode(data['battery'])}'),
                          Text('Flash: ${jsonEncode(data['flash'])}'),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
