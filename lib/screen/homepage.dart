// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace, prefer_const_literals_to_create_immutables

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String broker = 'broker.emqx.io';
  MqttServerClient client = MqttServerClient('broker.emqx.io', '');
  final String pubTopic = "python/mqtt/paratonsp";

  int voltage = 0;
  int ampere = 0;
  String date = '';

  Future<void> pullRefresh() async {
    await Future.delayed(Duration(seconds: 1));
    if (client.connectionStatus!.state == MqttConnectionState.disconnected) {
      onStart();
    }
  }

  /// The subscribed callback
  void onSubscribed(String topic) {
    if (kDebugMode) {
      print('MQTTClient::Subscribed to topic: $topic');
    }
  }

  /// The unsolicited disconnect callback
  void onDisconnected() {
    if (kDebugMode) {
      print('MQTTClient::Disconnected');
    }
  }

  /// The successful connect callback
  void onConnected() {
    if (kDebugMode) {
      print('OnConnected client callback - Client connection was successful');
    }
  }

  /// Pong callback
  void pong() {
    if (kDebugMode) {
      print('MQTTClient::Ping response received');
    }
  }

  void onStart() async {
    client.logging(on: false);
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;
    client.onSubscribed = onSubscribed;
    client.pongCallback = pong;
    final connMess = MqttConnectMessage()
        .withClientIdentifier('Mqtt_MyClientUniqueId')
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    if (kDebugMode) {
      print('$broker client connecting....');
    }
    client.connectionMessage = connMess;

    try {
      await client.connect();
    } on NoConnectionException catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {}
        print('$broker client exception - $e');
      }
      client.disconnect();
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('$broker socket exception - $e');
      }
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      if (kDebugMode) {
        print('$broker client connected');
      }
    } else {
      if (kDebugMode) {
        print(
            '$broker client connection failed - disconnecting, status is ${client.connectionStatus}');
      }
      client.disconnect();
      exit(-1);
    }

    const topic = 'python/mqtt/paratonsp';
    client.subscribe(topic, MqttQos.atMostOnce);
    if (kDebugMode) {
      print('Subscribing to the $topic topic');
    }

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      var res = jsonDecode(pt);
      if (!mounted) return;
      setState(() {
        voltage = res['voltage'];
        ampere = res['ampere'];
        date = res['date'];
      });
    });
  }

  @override
  void initState() {
    onStart();
    super.initState();
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color colorStatus;
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      colorStatus = Colors.blueAccent;
    } else {
      colorStatus = Colors.red;
    }
    double voltageD = voltage / 10;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: pullRefresh,
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const Text(
                //   "Project Eudora",
                //   style: TextStyle(
                //     fontSize: 24,
                //     color: Colors.blueGrey,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                // const Text("Lorem Ipsum"),
                // Icon(
                //   Icons.electrical_services_sharp,
                //   size: 32,
                //   color: colorStatus,
                // ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorStatus.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.electrical_services,
                                  size: 16,
                                  color: colorStatus,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  voltageD.toString(),
                                  style: TextStyle(
                                    fontSize: 32,
                                    color: colorStatus,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "V",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: colorStatus,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              date,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: colorStatus.withOpacity(0.2),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                ampere.toString(),
                                style: TextStyle(
                                  fontSize: 32,
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "A",
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 1000),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
