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
        cpu_address      		: in  std_logic_vector(2 downto 0);
        data_in          		: in  std_logic_vector(7 downto 0);
        data_out         : out std_logic_vector(7 downto 0);		  
        enable           		: in  std_logic;
        req_read         		: in  std_logic;
        req_write        		: in  std_logic;
        sigOut     				: out std_logic;
        sigIN		         : in  std_logic				
   );
end oneshot;
 
architecture Behavioral of oneshot is

    signal sigOutintern     			: std_logic := '0';
    signal FB00     					   : std_logic := '0';	 
    signal counter_value      		: unsigned(31 downto 0) := (others => '0');
    constant counterZero      		: unsigned(31 downto 0)  := to_unsigned (0, 32);
    constant counterEnd      		   : unsigned(31 downto 0)  := to_unsigned ((500), 32);

    signal grhk        : std_logic_vector(31 downto 0);
	 
    signal counterEnd2      : unsigned(31 downto 0) := (others => '0');

    signal regmux_select        : std_logic_vector(1 downto 0) := "00";
    signal regmux_output        : std_logic_vector(31 downto 0);
    signal regmux_updated       : std_logic_vector(31 downto 0);

begin 


	sigOut <= sigOutintern; 

    with cpu_address select
        data_out <=
            --status_register_value when "000",
            regmux_output(7  downto  0) when "100",
            regmux_output(15 downto  8) when "101",
            regmux_output(23 downto 16) when "110",
            regmux_output(31 downto 24) when "111",
            grhk(31 downto 24) when others;

    with regmux_select select
        regmux_output <= 
            std_logic_vector(counterEnd2  ) when "00",
            --std_logic_vector(upcounter_latch  ) when "01",
            --std_logic_vector(downcounter_value) when "10",
            --std_logic_vector(downcounter_start) when "11",
            std_logic_vector(counterEnd2) when others;

    with cpu_address(1 downto 0) select
        regmux_updated <= 
             regmux_output(31 downto 8)  & data_in                               when "00",
             regmux_output(31 downto 16) & data_in & regmux_output(7  downto 0)  when "01",
             regmux_output(31 downto 24) & data_in & regmux_output(15 downto 0)  when "10",
                                           data_in & regmux_output(23 downto 0)  when "11",
                                           data_in & regmux_output(23 downto 0)  when others;



oneshot_proc: process(clk)
begin
	if rising_edge(clk) then


		if reset = '1' then
                sigOutintern   <= '0';
                FB00   <= '0';	
                counterEnd2    <= (others => '0');	
                grhk    <= "00000000000000000000000000000000";						 
			counter_value  <= counterZero;
					 



--;----------------------------------------------------------------------------
		elsif sigIN = '1' then
					
			--if counter_value = counterEnd and FB00 = '0' then
			if counter_value = counterEnd2 and FB00 = '0' then			
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
--;----------------------------------------------------------------------------

		if enable = '1' and req_write = '1' then
					
          if cpu_address = "000" then
             regmux_select <= data_in(1 downto 0);
          elsif cpu_address(2) = '1' then
              case regmux_select is
                     when "00" => counterEnd2   <= unsigned(regmux_updated);
                     --when "01" => upcounter_latch   <= unsigned(regmux_updated);
                     --when "10" => downcounter_value <= unsigned(regmux_updated);
                     --when "11" => downcounter_start <= unsigned(regmux_updated);
                     when others =>
              end case;				 
			end if;
						
		end if;



--;----------------------------------------------------------------------------



	end if;


	
	end process;	
end Behavioral;
