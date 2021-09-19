USBHost HID Class Sample Readme
-------------------------------

This demo will read in data from interrupt endpoint on a HID class devices and output 
the received data to the UART interface. It will not check the device type connected 
although this can be changed to check for specific HID class devices.

It has been tested with various keyboards, mice and joysticks. It will automatically
determine the report size based on the maxPacketSize of the report endpoint.

The device should be plugged into USB Port 2.

Restrictions:
- N/A

Known Issues:
- N/A
