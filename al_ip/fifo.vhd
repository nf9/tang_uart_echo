----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/14/2019 10:29:52 AM
-- Design Name: 
-- Module Name: EG_LOGIC_FIFO - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity EG_LOGIC_FIFO is
	Generic(
			ADDR_W	: integer	:= 4;					-- address width in bits
			DATA_W 	: integer	:= 8; 				-- data width in bits
			BUFF_L	: integer 	:=16;					-- buffer length must be less than address space as in  BUFF_L <or= 2^(ADDR_W)-1
			ALMST_F	: integer 	:= 3;					-- fifo flag for almost full regs away from empty fifo
			ALMST_E	: integer	:= 3;						-- fifo regs away from empty fifo
			
			DATA_WIDTH_W			: integer	:= 8;
			DATA_DEPTH_W			: integer	:= 512;
			DATA_WIDTH_R			: integer	:= 8;
			DATA_DEPTH_R			: integer	:= 512;
			ENDIAN				: string	:= "BIG";
			RESETMODE			: string	:= "ASYNC";
			REGMODE_R			: string	:= "NOREG";
			E					: integer	:= 0;
			F					: integer	:= 512;
			ASYNC_RESET_RELEASE	: string	:= "ASYNC"
			
			
			);
    Port ( rst : in STD_LOGIC;
           di : in STD_LOGIC_VECTOR (7 downto 0);
           clkw : in STD_LOGIC;
           we : in STD_LOGIC;
           csw : in STD_LOGIC_VECTOR (2 downto 0);
           do : out STD_LOGIC_VECTOR (7 downto 0);
           clkr : in STD_LOGIC;
           re : in STD_LOGIC;
           csr : in STD_LOGIC_VECTOR (2 downto 0);
           ore : in STD_LOGIC;
           empty_flag : out STD_LOGIC;
           aempty_flag : out STD_LOGIC;
           full_flag : out STD_LOGIC;
           afull_flag : out STD_LOGIC);
end EG_LOGIC_FIFO;

architecture Behavioral of EG_LOGIC_FIFO is


	type reg_file_type is array (0 to ((2**ADDR_W) - 1)) of std_logic_vector(DATA_W - 1 downto 0);
	
	-----memory, pointers, and flip flops-------
	signal mem_array					: reg_file_type ;
	signal rd_ptr, wr_ptr 			: std_logic_vector(ADDR_W-1 downto 0); 		-- current pointers
	signal rd_ptr_nxt					: std_logic_vector(ADDR_W-1 downto 0); 		-- next pointer
	signal wr_ptr_nxt 				: std_logic_vector(ADDR_W-1 downto 0); 		-- next pointer
	signal full_ff, empty_ff		: std_logic;																		-- full and empty flag flip flops
	signal full_ff_nxt 				: std_logic;																		-- full and empty flag flip flops for next state
	signal empty_ff_nxt 				: std_logic;
	signal almst_f_ff					: std_logic;																		-- watermark flip flops for almost full/empty flags
	signal almst_e_ff					: std_logic;
	signal almst_f_ff_nxt			: std_logic;																		-- watermark flip flops for almost full/empty flags for next state
	signal almst_e_ff_nxt			: std_logic;
	signal q_reg, q_next				: std_logic_vector(ADDR_W downto 0);			-- data counter
	signal q_add, q_sub	, err			: std_logic;

	---------------------------------------------------

begin

	---------- Process to update read, write, full, and empty on clock edges
	reg_update :	
	process(clkw) 
	begin
		if rising_edge(clkw) then
			if (rst = '0')  then
				rd_ptr <= (others => '0');
				wr_ptr <= (others => '0');
				full_ff <= '0';
				empty_ff <= '1';
				almst_f_ff <= '0';
				almst_e_ff <= '1';
				q_reg <= (others => '0');
			else
				rd_ptr <=	rd_ptr_nxt;	
				wr_ptr <= wr_ptr_nxt;
				full_ff <= full_ff_nxt;
				empty_ff <= empty_ff_nxt;
				almst_f_ff <= almst_f_ff_nxt;
				almst_e_ff <= almst_e_ff_nxt;			
				q_reg <= q_next;
			end if;	-- end of n_reset if
		end if;	-- end of rising_edge(clkw) if
	end process;

	  -- --------------Process to control almost full and almost emptly flags
	Wtr_Mrk_Cont:
	process(q_reg, almst_e_ff, almst_f_ff)
	begin
		almst_e_ff_nxt <= almst_e_ff;
		almst_f_ff_nxt <= almst_f_ff;		
		   --check to see if wr_ptr is ALMST_E away from rd_ptr (aka almost empty)
		if(unsigned(q_reg) < (ALMST_E  )) then
			almst_e_ff_nxt <= '1';
		else
			almst_e_ff_nxt<= '0';
		end if;
		if(unsigned(q_reg) > (BUFF_L-1-ALMST_F ))  then  
			almst_f_ff_nxt<= '1';
		else
			almst_f_ff_nxt <= '0';
		end if;	
	end process;
		
	
	----------- Process to control read and write pointers and empty/full flip flops
	Ptr_Cont :	
	process(we, re, wr_ptr, rd_ptr, empty_ff, full_ff, q_reg)                     

	begin
		wr_ptr_nxt <= wr_ptr;											-- no change to pointers
		rd_ptr_nxt <= rd_ptr;
		full_ff_nxt <= full_ff;
		empty_ff_nxt <= empty_ff;
		q_add <= '0';
		q_sub <= '0';

		---------- check if fifo is full during a write attempt, after a write increment counter
		----------------------------------------------------
		if(we = '1' and re = '0') then
			if(full_ff = '0') then
				if(unsigned(wr_ptr) < BUFF_L-1 ) then      		
					q_add <= '1';
					wr_ptr_nxt <= std_logic_vector(unsigned(wr_ptr) + 1)  ;
					empty_ff_nxt <= '0';
				else	
					wr_ptr_nxt <= (others => '0');				
					empty_ff_nxt <= '0';  
				end if; 
				-- check if fifo is full
				if ((unsigned(wr_ptr) + 1) = unsigned(rd_ptr) or (unsigned(wr_ptr) = (BUFF_L-1) and unsigned(rd_ptr) = 0)) then      
					full_ff_nxt <= '1';
				end if ;
			end if;
		end if;	
		---------- check to see if fifo is empty during a read attempt, after a read decrement counter
		---------------------------------------------------------------
		if(we = '0' and re = '1') then	
			if(empty_ff = '0') then
				if(unsigned(rd_ptr) < BUFF_L-1 ) then   			
					if(unsigned(q_reg) > 0) then
						q_sub <= '1';
					else
						q_sub <= '0';
					end if;
					rd_ptr_nxt <= std_logic_vector( unsigned(rd_ptr) + 1);
					full_ff_nxt <= '0';
				else	
					rd_ptr_nxt <= (others => '0');  
					full_ff_nxt <= '0';		
				end if;
				-- check if fifo is empty
				if ((unsigned(rd_ptr)  + 1) = unsigned(wr_ptr) or (unsigned(rd_ptr) = (BUFF_L-1) and unsigned(wr_ptr) = 0 )) then     
					empty_ff_nxt <= '1';
				end if ;
			end if;
		end if;
		-----------------------------------------------------------------
		if(we = '1' and re = '1') then
			if(unsigned(wr_ptr) < BUFF_L-1 ) then  		
				wr_ptr_nxt <= std_logic_vector( unsigned(wr_ptr)  + 1);	
			else											
				wr_ptr_nxt <=  (others => '0');
			end if;
			if(unsigned(rd_ptr) < BUFF_L-1 ) then      		
				rd_ptr_nxt <= std_logic_vector( unsigned(rd_ptr) + 1);		
			else
				rd_ptr_nxt <= (others => '0');
			end if;
		end if;
	end process;


	-------- Process to control memory array writing and reading		
	mem_cont :	
	process(clkw)   		
	begin
		if rising_edge(clkw) then
			if( rst = '0') then
				mem_array <= (others => (others => '0'));  			-- reset memory array
				err <= '0';
			else
				-- if write enable and not full then latch in data and increment wright pointer
				if( we = '1') and (full_ff = '0') then
					mem_array (to_integer(unsigned(wr_ptr))) <=  di ;
					err <= '0';
				elsif(we = '1') and (full_ff = '1') then					-- check if full and trying to write
					err <= '1';
				end if ;
				-- if read enable and fifo not empty then latch data out and increment read pointer
				if( re = '1') and (empty_ff = '0') then
					do <= mem_array (to_integer(unsigned(rd_ptr)));
					err <= '0';
				elsif(re = '1') and (empty_ff = '1') then			-- check if empty and trying to read 
					err <= '1';
				end if ;
			end if;	-- end of rst if
		end if;	-- end of rising_edge(clkw) if
	end process;
		
	-------- counter to keep track of almost full and almost empty 
	q_next <= std_logic_vector(unsigned(q_reg) + 1) when q_add = '1' else
						std_logic_vector(unsigned(q_reg) - 1) when q_sub = '1' else
						q_reg;
		
	-------- connect ff to output ports
	full_flag <= full_ff;
	empty_flag <= empty_ff;
	aempty_flag <= almst_e_ff; 
	afull_flag <= almst_f_ff;
	--data_count <= q_reg;



end Behavioral;
