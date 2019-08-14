-- Testbench created online at:
--   www.doulos.com/knowhow/perl/testbench_creation/
-- Copyright Doulos Ltd
-- SD, 03 November 2002

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity top_tb is
end;

architecture bench of top_tb is

  component top
  	port(
  		clk : in std_logic;
  		reset: in std_logic;
  		tx: out std_logic;
  		rx: in std_logic
  		);		
  end component;

  signal clk: std_logic := '0';
  signal reset: std_logic := '0';
  signal tx: std_logic := '1';
  signal rx: std_logic := '1';

begin
  clk <= '1' after 0.5 ns when clk = '0' else
         '0' after 0.5 ns when clk = '1';

  uut: top port map ( clk   => clk,
                      reset => reset,
                      tx    => tx,
                      rx    => rx );

  stimulus: process
  begin
    reset <= '0';
    
    wait for 2ns;
    
    reset <= '1';

    for ii in 0 to 7 loop
    
    rx <= '0';
    wait for 1.5us;
    rx <= '0';
    wait for 1.25us;
    rx <= '1';
    wait for 1.25us;
    rx <= '0';
    wait for 1.25us;
    rx <= '0';
    wait for 1.25us;
    rx <= '1';
    wait for 1.25us;
    rx <= '0';
    wait for 1.25us;
    rx <= '0';
    wait for 1.25us;
    rx <= '1';
    wait for 5us;
    
    rx <= '0';
    wait for 1.5us;
    rx <= '1';
    wait for 1.25us;
    rx <= '1';
    wait for 1.25us;
    rx <= '0';
    wait for 1.25us;
    rx <= '0';
    wait for 1.25us;
    rx <= '1';
    wait for 1.25us;
    rx <= '1';
    wait for 1.25us;
    rx <= '0';
    wait for 1.25us;
    rx <= '0';
    wait for 1.25us;
    rx <= '1';

    end loop;
    
    -- Put initialisation code here


    -- Put test bench stimulus code here

    wait;
  end process;


end;
