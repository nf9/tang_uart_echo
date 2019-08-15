import_device eagle_s20.db -package BG256
open_project uart_echo.al
elaborate -top top
read_adc "constraint/io.adc"
optimize_rtl
report_area -file "uart_echo_rtl.area"

export_db "uart_echo_rtl.db"
optimize_gate -packarea "uart_echo_gate.area"
legalize_phy_inst
export_db "uart_echo_gate.db"
place
route
report_area -io_info -file "uart_echo_phy.area"
export_db "uart_echo_pr.db"
bitgen -bit "uart_echo.bit" -version 0X00 -g ucode:00000000000000000000000000000000
download -bit "uart_echo.bit" -mode jtag -spd 7 -sec 64 -cable 0
