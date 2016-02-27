--
--
--		Version 1.1
--
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity int1 is
   port
   (
			clk              		: in  std_logic;
         reset            		: in  std_logic;
         cpu_address      		: in  std_logic_vector(2 downto 0);
         data_in          		: in  std_logic_vector(7 downto 0);
         enable           		: in  std_logic;
         req_read         		: in  std_logic;
         req_write        		: in  std_logic;
         interruptOut     		: out std_logic;
         interruptIN_00       : in  std_logic;	
         test1     				: out std_logic;		
         test2     				: out std_logic				
   );
end int1;
 
architecture Behavioral of int1 is

    signal interruptInternal_00     : std_logic := '0';
    signal Clear00     					: std_logic := '0';
    signal FB00     					   : std_logic := '0';	 
    signal counter_value      		: unsigned(27 downto 0) := (others => '0');
    constant counterZero      		: unsigned(27 downto 0)  := to_unsigned (0, 28);
    constant counterEnd      		   : unsigned(27 downto 0)  := to_unsigned ((200), 28);

	begin 

		interruptOut <= interruptInternal_00;

		test1 <= interruptInternal_00; 

		test2 <= FB00; 


	 int1_proc: process(clk)
	 begin
		if rising_edge(clk) then


					if reset = '1' then
                interruptInternal_00   <= '0';
					-- interruptOut <= '0';
                Clear00   <= '0';						 
                FB00   <= '0';	
					 counter_value  <= counterZero;
					 



--;----------------------------------------------------------------------------
					elsif interruptIN_00 = '1' and Clear00 = '0' then
					
							if counter_value = counterEnd and FB00 = '0' then
							interruptInternal_00 <= '0';
							counter_value  <= counterZero;
							FB00   <= '1';
					
					
							elsif FB00 = '0' then
							counter_value <= counter_value + 1;
							interruptInternal_00 <= '1';
							FB00   <= '0';
							
							end if;

					elsif interruptIN_00 = '1' and Clear00 = '1' then

							interruptInternal_00 <= '0';
							counter_value  <= counterZero;
							FB00   <= '1';



					elsif interruptIN_00 = '0' then

							counter_value  <= counterZero;
							interruptInternal_00 <= '0';
							FB00 <= '0';
							Clear00 <= '0';

					end if;
--;----------------------------------------------------------------------------
--;----------------------------------------------------------------------------

					if enable = '1' and req_write = '1' then
					
						if cpu_address = "000" then
							Clear00 <= data_in(0);
						end if;
						
					end if;







--;----------------------------------------------------------------------------

--					if Clear00 = '0' and interruptIN_00 = '1' and FB00 = '0' then
--						interruptInternal_00 <= interruptIN_00;	
--						FB00 <= '1';	
--						counter_value <= (others => '0'); 						
--					end if;
					



--					if Clear00 = '0' and interruptIN_00 = '1' and FB00 = '1' then
--						if counter_value = "111111" then
--							interruptInternal_00 <= '0';
						
--						elsif enable = '1' and req_write = '1' then
--								if cpu_address = "000" then
--									Clear00 <= data_in(0);
--								end if;						
--						else
--							counter_value <= counter_value + 1;
--							interruptInternal_00 <= interruptIN_00;
--							
--						end if;						
--					end if;



--					if Clear00 = '1' and interruptIN_00 = '1' and FB00 = '1' then
--
--						interruptInternal_00   <= '0';
--						Clear00   <= '0';						 
--						FB00   <= '0';	
						
--					end if;






			end if;


	
		end process;	
end Behavioral;