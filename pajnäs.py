#!//opt/bin/lv_micropython -i
#import utime as time
#!/opt/bin/lv_micropython
import sys
print("Running the Unix version")

import lvgl as lv
import time
import SDL
print("Running the Unix version")
SDL.init(w=320,h=240)

lv.init()

LV_DEMO_WIDGETS_SLIDESHOW = 0
#LV_THEME_DEFAULT_COLOR_PRIMARY=lv.color_hex(0x01a2b1)
#LV_THEME_DEFAULT_COLOR_SECONDARY=lv.color_hex(0x44d1b6)

LV_LED_BRIGHT_MIN = 120
LV_LED_BRIGHT_MAX = 255

LV_DPI =130
LV_ANIM_REPEAT_INFINITE = -1

# Register SDL display driver.

draw_buf = lv.disp_draw_buf_t()
buf1_1 = bytearray(480*10)
draw_buf.init(buf1_1, None, len(buf1_1)//4)
disp_drv = lv.disp_drv_t()
disp_drv.init()
disp_drv.draw_buf = draw_buf
disp_drv.flush_cb = SDL.monitor_flush
disp_drv.hor_res = 320
disp_drv.ver_res = 240
disp_drv.register()

# Register evdev mouse driver (SDL doesn't work)
indev_drv = lv.indev_drv_t()
indev_drv.init()
indev_drv.type = lv.INDEV_TYPE.POINTER

import evdev
evdev_drv = evdev.mouse_indev()
indev_drv.read_cb = evdev_drv.mouse_read
indev_drv.register()


style = lv.style_t()
style.init()

# Set a background color and a radius
style.set_radius(0)
style.set_bg_opa(lv.OPA.COVER)
#style.set_bg_color(lv.palette_main(lv.PALETTE.BLUE))

# Add outline
#style.set_outline_width(2)
#style.set_outline_color(lv.palette_main(lv.PALETTE.BLUE))
#style.set_outline_pad(8)
#style.set_text_font(lv.FONT_MONTSERRAT_14)

#time.sleep(40)
# Create a screen and load it
scr=lv.obj()
lv.scr_load(scr)


def set_value(indic, v):
    meter.set_indicator_value(indic, v)

def set_arc_value(indic,v):
    meter.set_indicator_end_value(indic, v)
    
print("A")

#
# Tabs
#

tabview = lv.tabview(lv.scr_act(), lv.DIR.LEFT, 80)
#tabview.get_content().add_event_cb(scroll_begin_event, lv.EVENT.SCROLL_BEGIN, None)
tab1 = tabview.add_tab("Power")
tab2 = tabview.add_tab("Week")
tab3 = tabview.add_tab("Month")

#
# A simple meter
#
meter = lv.meter(tab1)
meter.add_style(style,0)
meter.center()
meter.set_size(240, 240)
meter.remove_style(None, lv.PART.INDICATOR)

print("B")
# Add a scale first
scale = meter.add_scale()

maxpow = 2000
meter.set_scale_range(scale,0,int(maxpow*1.5),200,170)
meter.set_scale_ticks(scale, int(maxpow/100), 5, 30, lv.palette_main(lv.PALETTE.LIGHT_BLUE))

indic1 = meter.add_arc(scale, 30, lv.palette_main(lv.PALETTE.BLUE), 0)

label1 = lv.label(meter)
label1.center()
#label1.set_width(150)
label1.set_style_text_align(lv.ALIGN.CENTER, 0)
#label1.align(lv.ALIGN.CENTER, 0, -40)

tstyle = lv.style_t()
tstyle.init()
tstyle.set_text_font(lv.font_montserrat_40)
label1.add_style(tstyle,0)
import mqtt


client_id = "pienes"
mqtt_server = "10.168.0.194"
topic_sub = "esp-p1reader/sensor/momentary_active_import/state"

def sub_cb(topic, msg):
  global indic
  global indic1
  global maxpow
  global label1
  print((topic, msg))
  pwr = int(float(msg)*1000)
  print(pwr)
  if pwr>maxpow:
      maxpow = pwr
      meter.set_scale_range(scale,0,int(pwr*1.5),200,170)
      
  #set_value(indic,pwr)
  set_arc_value(indic1,pwr)
  label1.set_text(str(int(pwr)))
  
def connect_and_subscribe():
  global client_id, mqtt_server, topic_sub
  client = mqtt.MQTTClient(client_id, mqtt_server,keepalive=3600)
  client.set_callback(sub_cb)
  client.connect()
  client.subscribe(topic_sub)
  print('Connected to %s MQTT broker, subscribed to %s topic' % (mqtt_server, topic_sub))
  return client

def restart_and_reconnect():
  print('Failed to connect to MQTT broker. Reconnecting...')
  time.sleep(10)
  #machine.reset()
  client.disconnect()
  connect_and_subscribe()
  
try:
  client = connect_and_subscribe()
except OSError as e:
  restart_and_reconnect()

while True:
  try:
      client.check_msg()
#      indev_drv.read_task()
      
  except OSError as e:
      #import traceback

      restart_and_reconnect()

