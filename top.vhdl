library ieee;
use ieee.std_logic_1164.all;

entity top is
	port(
		clk : in std_logic;
		reset: in std_logic;
		tx: out std_logic;
		rx: in std_logic
		);		
end entity;

architecture rtl of top is
	type rx_states is (idle, receiving, done);
	signal rx_state : rx_states;
	
	type tx_states is (idle, latch_next, latch_output, busy, transmitting, done);
	signal tx_state : tx_states;
	
	signal tx_data_top	:	STD_LOGIC_VECTOR(8-1 DOWNTO 0);
	signal rx_data_top	:	STD_LOGIC_VECTOR(8-1 DOWNTO 0);
	signal write_to_fifo : std_logic := '0';
	signal read_from_fifo : std_logic := '0';
	signal busy_rx : std_logic := '0';
	signal busy_tx : std_logic := '0';
	signal ena_tx : std_logic := '0';
	signal empty_flag : std_logic;
	signal full_flag : std_logic;



begin

	uart0: entity work.uart
		generic map(
			clk_freq		=> 24_000_000,	--frequency of system clock in Hertz
			baud_rate	=> 19_200,		--data link baud rate in bits/second
			os_rate		=> 16,			--oversampling rate to find center of receive bits (in samples per baud period)
			d_width		=> 8, 			--data bus width
			parity		=> 1,			--0 for no parity, 1 for parity
			parity_eo	=> '0')			--'0' for even, '1' for odd parity
		port map(
			clk		=> clk,				--system clock
			reset_n	=> reset,			--ascynchronous reset
			tx_ena	=> ena_tx,				--initiate transmission
			tx_data	=> tx_data_top,  	--data to transmit
			rx		=> rx,				--receive pin
			rx_busy	=> busy_rx,				--data reception in progress
			rx_error	=> open,				--start, parity, or stop bit error detected
			rx_data	=> rx_data_top,		--data received
			tx_busy	=> busy_tx,  			--transmission in progress
			tx => tx);					--transmit pin

	fifo0: entity work.al_fifo
		port map (
			di => rx_data_top, 
			rst	=> reset,
			clk	=> clk,
			we	=> write_to_fifo,
			re	=> read_from_fifo,
			do	=> tx_data_top,
			empty_flag => empty_flag,
			full_flag => full_flag
		);

	receive: process(clk, reset, rx) is
		begin
			if( reset = '0') then
				rx_state <= idle;
			elsif(clk'event and clk = '1') then
				case rx_state is
					when idle =>
						if(busy_rx = '1') then
							rx_state <= receiving;
						else
							rx_state <= idle;
						end if;
					when receiving =>
						if(busy_rx = '0') then
							rx_state <= done;
							write_to_fifo <= '1';
						else
							rx_state <= receiving;
						end if;
					when done =>
					   	write_to_fifo <= '0';
						rx_state <= idle;
				end case;
						
			end if;

	end process;
	
    transmit: process(clk, reset) is
		begin
			if( reset = '0') then
				tx_state <= idle;
			elsif(clk'event and clk = '1') then
				case tx_state is
					when idle =>
						if(full_flag = '1') then
						    read_from_fifo <= '1';
                            tx_state <= latch_output;
						else
							tx_state <= idle;
						end if;
					when latch_next =>
					   	read_from_fifo <= '1';
					   	tx_state <= latch_output;
					when latch_output =>
						read_from_fifo <= '0';
                        ena_tx <= '1';
                        tx_state <= busy;
                    when busy =>
                        tx_state <= transmitting;                    
					when transmitting =>
					    ena_tx <= '0';
						if(busy_tx = '0') then
							tx_state <= done;
						else
							tx_state <= transmitting;
						end if;
					when done =>
					    if(empty_flag = '0') then
					        tx_state <= latch_next;
					    else
						    tx_state <= idle;
						end if;
				end case;
						
			end if;

	end process;
	
	
	


end architecture;