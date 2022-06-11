
MVP on an IKEA SPARSNÄS clone, using an Adafruit 2.8" TFT on an RPI. 

Consumes mqtt from https://github.com/psvanstrom/esphome-p1reader to display things on screen.

How to get this working:

git submodule update --init --recursive

Then,

Edit the "FONT USAGE" section in lv_micropython/lib/lv_bindings/lv_conf.h and enable larger fonts ("1" means enabled):

#define LV_FONT_MONTSERRAT_14 1
#define LV_FONT_MONTSERRAT_16 1
#define LV_FONT_MONTSERRAT_20 1
#define LV_FONT_MONTSERRAT_30 1
#define LV_FONT_MONTSERRAT_40 1

* Build the lv_micropython - will take long time
* Build the ticktock tt database (not used yet)
* Install the adafruit tft thingy (see https://learn.adafruit.com/adafruit-pitft-28-inch-resistive-touchscreen-display-raspberry-pi/displaying-images, use hdmi mirroring)

Edit the pajnäs.py file to point at your own mqtt broker. 


