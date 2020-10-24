### Clock constraints ###
create_generated_clock -source [get_ports PixelClk] -multiply_by 7 [get_ports SerialClk]