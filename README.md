# tang_uart_echo
UART echo based on FIFO
## Contents
- **al_ip** Anlogic FIFO Hard IP and Vivado simulated FIFO
- **Constraint** IO Constraints for both TD and Vivado
- **Simulation** Test Bench
- **flow.tcl** Synthesis and upload .tcl script
- **top.vhdl** Top level source
- **uart.vhd** UART module
- **uart_echo.al** TD project file
- **uart_echo.xpr** Vivado Project File 

## How It works
THe UART module will interpret the IO lines. Once it is ready, it will be latched onto the FIFO input and enqueues the value. It will fill the FIFO until the watermark almost full is set. In this case, it is set to 8. The UART module will then dequeues the FIFO and transmit the value back.
## Test Bench
![alt text](https://raw.githubusercontent.com/nf9/tang_uart_echo/master/pics/sims.PNG "")
## FPGA Test
Tested with CP2012 USB UART Converter
![alt text](https://raw.githubusercontent.com/nf9/tang_uart_echo/master/pics/Test.PNG "")
