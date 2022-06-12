import sys
import time
from PyQt5.QtCore import QObject, QUrl, Qt, pyqtProperty
from PyQt5.QtWidgets import QApplication
from PyQt5.QtQml import QQmlApplicationEngine, qmlRegisterType
from PyQt5 import QtCore, QtGui
from PyQt5.QtQuick import QQuickView

app = QApplication(sys.argv)
view = QQuickView()
view.setSource(QUrl('full_gauge.qml'))
engine = view.engine()
rot = 4000.0
engine.rootContext().setContextProperty('gauge_value', rot)
view.show()
rot = 0.0
engine.rootContext().setContextProperty('gauge_value', rot)
view.update()
view.show()

import paho.mqtt.client as mqtt

client_id = "pienes"
mqtt_server = "10.168.0.194"

def on_message(client, userdata, msg):
     global maxpow

     print(msg.topic+" "+str(msg.payload))

     #print((topic, msg))
     #pwr = int(float(msg)*1000)
     #print(pwr)
     #if pwr>maxpow:
     #     maxpow = pwr
     #meter.set_scale_range(scale,0,int(pwr*1.5),200,170)
      
def on_connect(client, userdata, flags, rc):
    print("Connected with result code "+str(rc))

    # Subscribing in on_connect() means that if we lose the connection and
    # reconnect then subscriptions will be renewed.
    client.subscribe("esp-p1reader/sensor/momentary_active_import/state")
    
client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message

client.connect("10.168.0.194", 1883, 60)
client.loop_start()
sys.exit(app.exec_())
