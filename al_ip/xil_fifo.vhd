--------------------------------------------------------------
 --  Copyright (c) 2011-2021 Anlogic, Inc.
 --  All Right Reserved.
--------------------------------------------------------------
 -- Log	:	This file is generated by Anlogic IP Generator.
 -- File	:	/home/nf/uart_echo/al_ip/al_fifo.vhd
 -- Date	:	2019 08 13
 -- TD version	:	4.5.12562
--------------------------------------------------------------

LIBRARY ieee;
USE work.ALL;
	USE ieee.std_logic_1164.all;

ENTITY al_fifo IS
PORT (
	di	: IN STD_LOGIC_VECTOR(7 DOWNTO 0);

	rst	: IN STD_LOGIC;
	clk	: IN STD_LOGIC;
	we	: IN STD_LOGIC;
	re	: IN STD_LOGIC;
	do	: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	empty_flag		: OUT STD_LOGIC;
	afull_flag		: OUT STD_LOGIC;
	full_flag		: OUT STD_LOGIC
	);
END al_fifo;

ARCHITECTURE struct OF al_fifo IS

	BEGIN
	inst : entity work.EG_LOGIC_FIFO
		GENERIC MAP (
			DATA_WIDTH_W			=> 8,
			DATA_DEPTH_W			=> 512,
			DATA_WIDTH_R			=> 8,
			DATA_DEPTH_R			=> 512,
			ENDIAN				=> "BIG",
			RESETMODE			=> "ASYNC",
			REGMODE_R			=> "NOREG",
			E					=> 0,
			F					=> 512,
			ASYNC_RESET_RELEASE	=> "ASYNC"
		)
		PORT MAP (
			rst	=> rst,
			di	=> di,
			clkw	=> clk,
			we	=> we,
			csw	=> "111",
			clkr	=> clk,
			ore	=> '0',
			re	=> re,
			csr	=> "111",
			do	=> do,
			empty_flag	=> empty_flag,
			aempty_flag	=> OPEN,
			full_flag	=> full_flag,
			afull_flag	=> afull_flag
		);

END struct;
