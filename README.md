# IKEA Sparsnäs clone


Consumes mqtt from https://github.com/psvanstrom/esphome-p1reader to display things on screen.
HW: rpi with "official"  rpi 7 inch touch screen

## rpi installation

1. Scratch install an sd card with raspbian buster lite
2. Then follow the instructions for [Flutter-Pi](https://github.com/ardera/flutter-pi) exactly or it will not work.

## dev machine installation

1. Install flutter on your dev machine.

## building

1. flutter run

## exporting to rpi

Intentionally left blank

## directory structure

* mvp - early code built with circuitpython
* app - flutter-based frontend
* db - time series database-related

---

# Design Docs

## Consuming Data

The default behavior is to listen for messages from an [ESPHome P1 Reader](https://github.com/psvanstrom/esphome-p1reader).

Implemented: The app itself consumes the message *esp-p1reader/sensor/momentary_active_import/state* and displays the payload on the first page (the power gauge page).

Will be implemented:_All_ messages from the esp-p1reader are stored in an influxd database, using a [telegraf-influxd](https://www.influxdata.com/blog/mqtt-topic-payload-parsing-telegraf/) setup.


