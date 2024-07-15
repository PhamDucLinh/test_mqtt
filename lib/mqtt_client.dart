import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTClientWrapper {
  static final MqttServerClient _client =
  MqttServerClient.withPort('td88846f.ala.dedicated.aws.emqxcloud.com', '12344', 1883);
  static final StreamController<Map<String, dynamic>> _messageStreamController =
  StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get messageStream =>
      _messageStreamController.stream;

  static Future<bool> connect(String username, String password) async {
    _client.logging(on: true);
    _client.keepAlivePeriod = 60;
    _client.onConnected = onConnected;
    _client.onDisconnected = onDisconnected;
    _client.onSubscribed = onSubscribed;
    _client.onSubscribeFail = onSubscribeFail;
    _client.pongCallback = pong;

    final connMess = MqttConnectMessage()
        .withClientIdentifier('client_id')
        .authenticateAs(username, password)
        .keepAliveFor(60)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    _client.connectionMessage = connMess;

    try {
      await _client.connect();
    } catch (e) {
      print('Exception: $e');
      _client.disconnect();
      return false;
    }

    if (_client.connectionStatus!.state == MqttConnectionState.connected) {
      _client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
        final String payload =
        MqttPublishPayload.bytesToStringAsString(message.payload.message);

        // Parse the JSON payload
        try {
          final Map<String, dynamic> jsonData = jsonDecode(payload);
          _messageStreamController.add(jsonData);
        } catch (e) {
          print('Error parsing JSON: $e');
        }
      });
      return true;
    } else {
      _client.disconnect();
      return false;
    }
  }

  static void disconnect() {
    _client.disconnect();
  }

  static Future<bool> reconnect() async {
    try {
      await _client.connect();
      return true;
    } catch (e) {
      print('Exception: $e');
      return false;
    }
  }

  static void subscribe(String topic) {
    _client.subscribe(topic, MqttQos.atLeastOnce);
  }

  static void publish(String topic, String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  static void onConnected() {
    print('Connected');
  }

  static void onDisconnected() {
    print('Disconnected');
  }

  static void onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  static void onSubscribeFail(String topic) {
    print('Failed to subscribe $topic');
  }

  static void pong() {
    print('Ping response client callback invoked');
  }
}
