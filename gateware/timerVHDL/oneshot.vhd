--
--
--		Version 1.0
--
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity oneshot is
   port
   (
			clk              		: in  std_logic;
         reset            		: in  std_logic;
         sigOut     				: out std_logic;
         sigIN		         : in  std_logic				
   );
end oneshot;
 
architecture Behavioral of oneshot is

    signal sigOutintern     			: std_logic := '0';
    signal FB00     					   : std_logic := '0';	 
    signal counter_value      		: unsigned(27 downto 0) := (others => '0');
    constant counterZero      		: unsigned(27 downto 0)  := to_unsigned (0, 28);
    constant counterEnd      		   : unsigned(27 downto 0)  := to_unsigned ((500), 28);

	begin 


		sigOut <= sigOutintern; 


	 oneshot_proc: process(clk)
	 begin
		if rising_edge(clk) then


					if reset = '1' then
                sigOutintern   <= '0';
                FB00   <= '0';					 
					 counter_value  <= counterZero;
					 



--;----------------------------------------------------------------------------
					elsif sigIN = '1' then
					
							if counter_value = counterEnd and FB00 = '0' then
							sigOutintern <= '0';
							counter_value  <= counterZero;
							FB00   <= '1';
					
					
							elsif FB00 = '0' then
							counter_value <= counter_value + 1;
							sigOutintern <= '1';
							FB00   <= '0';
							
							end if;


					elsif sigIN = '0' then

							counter_value  <= counterZero;
							sigOutintern <= '0';
							FB00 <= '0';

					end if;
--;----------------------------------------------------------------------------




			end if;


	
		end process;	
end Behavioral;