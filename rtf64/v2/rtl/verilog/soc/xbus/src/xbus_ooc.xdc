create_clock -period 6.060 [get_ports PixelClk]
create_generated_clock -source [get_ports PixelClk] -multiply_by 7 [get_ports SerialClk]