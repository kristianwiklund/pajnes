import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gauges/gauges.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:math';
import "dart:ui";
import 'package:slide_digital_clock/slide_digital_clock.dart';

//import "powerpage.dart";

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.unknown,
        PointerDeviceKind.stylus,
        
      };
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pajnäs',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Current Power Consumption'),
      scrollBehavior: AppScrollBehavior(),
    );
  }
}


class MyHomePage extends StatefulWidget {

  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {

  int _power = 0;
  double _max = 5000; // start at 5 kW
  
  //  String broker           = '10.168.0.1';
  int port                = 1880;
  String username         = '';
  String passwd           = '';
  String clientIdentifier = 'pajnaes';

  //  mqtt.MqttClient client;
  mqtt.MqttConnectionState connectionState = mqtt.MqttConnectionState.faulted;
  mqtt.MqttClient client = MqttServerClient("10.168.0.1", 'pajnäs');
  
  double _temp = 20;

  StreamSubscription? subscription;

  MyHomePageState() {
  	_connect();
  }

  void _subscribeToTopic(String topic) {
    if (connectionState == mqtt.MqttConnectionState.connected) {
      //        //print('[MQTT client] Subscribing to ${topic.trim()}');
      client.subscribe(topic, mqtt.MqttQos.exactlyOnce);
    }
  }

  
  void _connect() async {
    /// First create a client, the client is constructed with a broker name, client identifier
    /// and port if needed. The client identifier (short ClientId) is an identifier of each MQTT
    /// client connecting to a MQTT broker. As the word identifier already suggests, it should be unique per broker.
    /// The broker uses it for identifying the client and the current state of the client. If you don’t need a state
    /// to be hold by the broker, in MQTT 3.1.1 you can set an empty ClientId, which results in a connection without any state.
    /// A condition is that clean session connect flag is true, otherwise the connection will be rejected.
    /// The client identifier can be a maximum length of 23 characters. If a port is not specified the standard port
    /// of 1883 is used.
    /// If you want to use websockets rather than TCP see below.
    ///
    client = MqttServerClient("10.168.0.1", 'pajnäs');
    //    client.port = 1880;

    /// A websocket URL must start with ws:// or wss:// or Dart will throw an exception, consult your websocket MQTT broker
    /// for details.
    /// To use websockets add the following lines -:
    /// client.useWebSocket = true;
    /// client.port = 80;  ( or whatever your WS port is)
    /// Note do not set the secure flag if you are using wss, the secure flags is for TCP sockets only.
    /// Set logging on if needed, defaults to off
    //client.logging(on: true);

    /// If you intend to use a keep alive value in your connect message that is not the default(60s)
    /// you must set it here
    client.keepAlivePeriod = 30;

    /// Add the unsolicited disconnection callback
    client.onDisconnected = _onDisconnected;

    /// Create a connection message to use or use the default one. The default one sets the
    /// client identifier, any supplied username/password, the default keepalive interval(60s)
    /// and clean session, an example of a specific one below.
    final mqtt.MqttConnectMessage connMess = mqtt.MqttConnectMessage()
    .withClientIdentifier(clientIdentifier)
    .startClean() // Non persistent session for testing
    .keepAliveFor(30)
    .withWillQos(mqtt.MqttQos.atMostOnce);
    //print('[MQTT client] MQTT client connecting....');
    client.connectionMessage = connMess;

    /// Connect the client, any errors here are communicated by raising of the appropriate exception. Note
    /// in some circumstances the broker will just disconnect us, see the spec about this, we however will
    /// never send malformed messages.
    try {
      await client.connect();
    } catch (e) {
      //print(e);
      _disconnect();
    }

    /// Check if we are connected
    if (client.connectionState == mqtt.MqttConnectionState.connected) {
      //print('[MQTT client] connected');
      setState(() {
          connectionState = client.connectionState!;
      });
    } else {
      //print('[MQTT client] ERROR: MQTT client connection failed - '
      //    'disconnecting, state is ${client.connectionState}');
      _disconnect();
    }

    /// The client has a change notifier object(see the Observable class) which we then listen to to get
    /// notifications of published updates to each subscribed topic.
    subscription = client.updates?.listen(_onMessage);

    _subscribeToTopic("esp-p1reader/sensor/momentary_active_import/state");
  }

  void _disconnect() {
    //print('[MQTT client] _disconnect()');
    client.disconnect();
    _onDisconnected();
  }

  void _onDisconnected() {
    //print('[MQTT client] _onDisconnected');
    setState(() {
        //topics.clear();
        connectionState = client.connectionState!;
        //subscription.cancel();
    });
    //print('[MQTT client] MQTT client disconnected');
  }

  int _onMessage(List<mqtt.MqttReceivedMessage> event) {
    //print(event.length);
    final mqtt.MqttPublishMessage recMess =
    event[0].payload as mqtt.MqttPublishMessage;
    final String message =
    mqtt.MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

    /// The above may seem a little convoluted for users only interested in the
    /// payload, some users however may be interested in the received publish message,
    /// lets not constrain ourselves yet until the package has been in the wild
    /// for a while.
    /// The payload is a byte buffer, this will be specific to the topic
    //print('[MQTT client] MQTT message: topic is <${event[0].topic}>, '
    //'payload is <-- ${message} -->');
    //print(client.connectionState);
    //print("[MQTT client] message with topic: ${event[0].topic}");
    //print("[MQTT client] message with message: ${message}");
    setState(() {
    	  var x = double.parse(message);
	      _power=(x*1000).round();
	      //print(x);
    });
    return (0);
  }


  PageController _controller = PageController(
    initialPage: 0,
  );

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return PageView(controller: _controller,
      scrollDirection: Axis.vertical,
        children: [powerpage(),
          daypage(),
          weekpage(),
          ],

          );

      
  }


  Widget daypage() {
    return Column(children: [
        Text("day view",
					  style: TextStyle(fontSize:20))
        ]);
    }

  Widget weekpage() {
    return Column(children: [
        Text("week view",
					style: TextStyle(fontSize:20))
    ]);
    }

  Widget powergauge() {
    final size = min(MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height)*.9;
    
    return SizedBox(
      width: size,
      height: size,
      child: RadialGauge(
				
				axes: [
					RadialGaugeAxis(
						minValue: 0,
						maxValue: _max,
						minAngle: -120,
						maxAngle: 120,
						radius: 0.6,
						width: 0.2,
						ticks: [
							RadialTicks(
								interval: 1000,
								alignment: RadialTickAxisAlignment.inside,
								color: Colors.blue,
								length: 0.2,
								children: [
									RadialTicks(
										ticksInBetween: 10,
										length: 0.075,
										color: Colors.grey[500]!),
							])
						],
						
						pointers: [
							RadialNeedlePointer(
								value: _power.toDouble(),
								thicknessStart: 20,
								thicknessEnd: 0,
								length: 0.6,
								knobRadiusAbsolute: 10,
								gradient: LinearGradient(
									colors: [
										Color(Colors.grey[400]!.value),
										Color(Colors.grey[400]!.value),
										Color(Colors.grey[600]!.value),
										Color(Colors.grey[600]!.value)
									],
									stops: [0, 0.5, 0.5, 1],
									begin: Alignment.topCenter,
									end: Alignment.bottomCenter,
								),
							),
						],
          ),
				],
      )
    );
  }

  Widget digitalclock() {
    return  DigitalClock(
                areaDecoration: BoxDecoration(color: Colors.transparent),
                areaAligment: AlignmentDirectional.center,
                hourMinuteDigitDecoration:
                    BoxDecoration(color: Colors.transparent),
                hourMinuteDigitTextStyle: TextStyle(fontSize: 15),
                secondDigitTextStyle: TextStyle(fontSize: 11),
              );
    }
  
  Widget powerpage() {
    //    return    		    FittedBox(child: powergauge()
    //        );

    //    return powergauge();

    return Column(children:  [
        Expanded(
          flex:1,
          child:
        Container(
            alignment: Alignment.topLeft,
            child: digitalclock(),
            ),
            ),
            Expanded(
              flex: 7,
              child: 
        Container(
           child:          powergauge(),
         ),
         ),
         Expanded(
           flex: 2,
           child:
         Container(
           child:         Text("$_power")
           ),
           ),
          ]);

  }
  

}
