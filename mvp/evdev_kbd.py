# LVGL indev driver for evdev mouse device
# (for the unix micropython port)

import ustruct
import select
import lvgl as lv

# Default crosshair cursor

# evdev driver for keyboard
class keyboard_indev:
    def __init__(self, device='/dev/input/event1'):

        # Open evdev and initialize members
        self.evdev = open(device, 'rb')
        self.poll = select.poll()
        self.poll.register(self.evdev.fileno())

        # Register LVGL indev driver
        self.indev_drv = lv.indev_drv_t()
        self.indev_drv.init()
        self.indev_drv.type = lv.INDEV_TYPE.KEYPAD
        self.indev_drv.read_cb = self.mouse_read
        self.indev = self.indev_drv.register()

    def keyboard_read(self, indev_drv, data) -> int:
        
        # Check if there is input to be read from evdev
        if not self.poll.poll()[0][1] & select.POLLIN:
            return 0

        # Read and parse evdev mouse data
        (tv_sec, tv_usec, type, code, value) = struct.unpack('llHHI',self.evdev.read(struct.calcsize(FORMAT)))

        # Data is relative, update coordinates
        #data.point.x += mouse_data[1]
        #data.point.y -= mouse_data[2]

        # Handle coordinate overflow cases
        #data.point.x = min(data.point.x, self.hor_res - 1)
        #data.point.y = min(data.point.y, self.ver_res - 1)
        #data.point.x = max(data.point.x, 0)
        #data.point.y = max(data.point.y, 0)

        # Update "pressed" status
        #data.state = lv.INDEV_STATE.PRESSED if ((mouse_data[0] & 1) == 1) else lv.INDEV_STATE.RELEASED

        # Draw cursor, if needed
        #if self.cursor: self.cursor(data)
        return 0

    def delete(self):
        self.evdev.close()
        if self.cursor and hasattr(self.cursor, 'delete'):
            self.cursor.delete()
        self.indev.enable(False)
