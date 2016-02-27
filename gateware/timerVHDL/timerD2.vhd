--
-- register layout:
--
-- address   read value                           write operation
-- --------- ------------------------------------ -------------------------------------
-- base+0    status register                      set status register  
-- base+1      (unused)                           perform operation according to value written
-- base+2      (unused)                             (no operation)
-- base+3      (unused)                             (no operation)
-- base+4    muxed register value (low byte)      update muxed register value
-- base+5    muxed register value                 update muxed register value
-- base+6    muxed register value                 update muxed register value
-- base+7    muxed register value (high byte)     update muxed register value
--
--
-- operation values (for writes to base+1):
--   00 -- acknowledge interrupt
--   01 -- reset upcounter value to zero
--   02 -- update latched value from upcounter value
--   03 -- reset downcounter
--   10 -- set register mux select to upcounter current
--   11 -- set register mux select to upcounter latched
--   12 -- set register mux select to downcounter current
--   13 -- set register mux select to downcountre reset
--
--
-- control/status register layout (for r/w to base+0):
--   bits 0, 1, -- register mux select (controls which register is visible in registers at base+4 through base+7):
--        0  0  upcounter current value
--        0  1  upcounter latched value
--        1  0  downcounter current value
--        1  1  downcounter reset value
--     (bits 2, 3, 4, 5 are currently unused)
--   bit 6 -- countdown timer interrupt enable (0=disable, 1=enable)
--   bit 7 -- interrupt flag (0=no interrupt, 1=one or interrupts occurred but not yet acknowledged)
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity timerD2 is
    port ( clk              : in  std_logic;
           reset            : in  std_logic;
           cpu_address      : in  std_logic_vector(2 downto 0);
           data_in          : in  std_logic_vector(7 downto 0);
           data_out         : out std_logic_vector(7 downto 0);
           enable           : in  std_logic;
           req_read         : in  std_logic;
           req_write        : in  std_logic;
			  testPin1     	 : out std_logic;	
			  testPin2     	 : out std_logic;				  
			  FIN_out		    : out std_logic;	  
			  interruptIN		 : in  std_logic
        --   interrupt        : out std_logic
    );
end timerD2;

architecture Behavioral of timerD2 is

    signal upcounter_value      : unsigned(31 downto 0) := (others => '0');
    signal upcounter_latch      : unsigned(31 downto 0) := (others => '0');
    signal downcounter_value    : unsigned(31 downto 0) := (others => '0');
    signal downcounter_start    : unsigned(31 downto 0) := (others => '0');
    signal downcounter_startB   : unsigned(31 downto 0) := (others => '0');	 

    -- if using frequencies > 128MHz this counter will need to be wider than 7 bits
  --  signal counter_prescale     : unsigned(6 downto 0)  := (others => '0');
  --  constant prescale_wrap      : unsigned(6 downto 0)  := to_unsigned(clk_frequency/10, 7 );   -- for 128MHz


    signal DowncounterStartBit    : std_logic := '0';
 
 
    signal regmux_select        : std_logic_vector(1 downto 0) := "00";

    signal regmux_output        : std_logic_vector(31 downto 0);
    signal regmux_updated       : std_logic_vector(31 downto 0);
    signal status_register_value  : std_logic_vector(7 downto 0);
	 
	 signal FIN_internA     	  	  : std_logic := '0';	
	 signal FIN_internB     	  	  : std_logic := '0';	
	 signal FIN_FB00	 				: std_logic := '0';
	 signal FIN_signalack			: std_logic := '0'; 
	 signal FeedB     			  : std_logic := '0';
	 signal intINintern  		  : std_logic := '0';	
	 signal TestSig_00  		     : std_logic := '0';	
	 signal TestSig_01  		     : std_logic := '0';		 

    signal FINcounter_value      		: unsigned(27 downto 0) := (others => '0');
    constant FINcounterZero      		: unsigned(27 downto 0)  := to_unsigned (0, 28);
    constant FINcounterEnd      		   : unsigned(27 downto 0)  := to_unsigned ((2000), 28);


begin

 --   interrupt <= (interrupt_signal and interrupt_enable);

    testPin2 <= TestSig_00;
    testPin1 <= TestSig_01; 
    FIN_out <= FIN_internB; 


    with cpu_address select
        data_out <=
            status_register_value when "000",
            regmux_output(7  downto  0) when "100",
            regmux_output(15 downto  8) when "101",
            regmux_output(23 downto 16) when "110",
            regmux_output(31 downto 24) when "111",
            status_register_value when others;

    --status_register_value <= interrupt_signal & interrupt_enable & "0000" & regmux_select;
	 status_register_value <=  "000000" & regmux_select;

    with regmux_select select
        regmux_output <= 
            std_logic_vector(upcounter_value  ) when "10",
            std_logic_vector(upcounter_latch  ) when "11",
            std_logic_vector(downcounter_value) when "00",
            std_logic_vector(downcounter_start) when "01",
            std_logic_vector(downcounter_start) when others;



    with cpu_address(1 downto 0) select
        regmux_updated <= 
             regmux_output(31 downto 8)  & data_in                               when "00",
             regmux_output(31 downto 16) & data_in & regmux_output(7  downto 0)  when "01",
             regmux_output(31 downto 24) & data_in & regmux_output(15 downto 0)  when "10",
                                           data_in & regmux_output(23 downto 0)  when "11",
                                           data_in & regmux_output(23 downto 0)  when others;

    timerD2_proc: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                upcounter_value    <= (others => '0');
                upcounter_latch    <= (others => '0');
                downcounter_value  <= (others => '0');
                downcounter_start  <= (others => '0');
					 downcounter_startB  <= (others => '0');
                --counter_prescale   <= (others => '0');
                DowncounterStartBit   <= '0';
             --   interrupt_signal   <= '0';
                regmux_select      <= "00";
                intINintern   <= '0';	
					 FIN_internA	  <= '0';
					 FIN_internB	  <= '0';
					 FIN_FB00	 <= '0';				 	
					 FIN_signalack <= '0';						 
                FeedB   <= '0';	 
					 TestSig_00 <= '0';	
					 FINcounter_value  <= FINcounterZero;					 
            end if;
--;----------------------------------------------------------------------------
--;----------------------------------------------------------------------------					 
				if interruptIN = '1' and FeedB = '0' then
							intINintern <= '1';	
							FeedB <= '1';
							upcounter_value <= (others => '0');
							DowncounterStartBit	<= '0';	
				end if;
				
				if FeedB = '1' then
							intINintern <= '1';						
				end if;	
				if FeedB = '0' then
							intINintern <= '0';	
				end if;

				
--;----------------------------------------------------------------------------
--;----------------------------------------------------------------------------					
					 
				if TestSig_00 = '1' then
					upcounter_value <= upcounter_value + 1;
					--TestSig_01 <= '1';
				elsif TestSig_00 = '0' then
					upcounter_value <= upcounter_value;		
					--TestSig_01 <= '0';					
				end if;                  							
--;----------------------------------------------------------------------------								
--;----------------------------------------------------------------------------

            if DowncounterStartBit = '1' then
				
					FeedB <= '0';	
					TestSig_01 <= '1';					--	******				

					if downcounter_value = 0 then
                  FIN_internA <= '1';
						FIN_signalack	<= '0';						
					else
                  downcounter_value <= downcounter_value - 1;
                  FIN_internA <= '0';										
					end if;	
								
            elsif DowncounterStartBit = '0' then
						downcounter_value <= downcounter_value;
                  FIN_internA <= '0';	
						TestSig_01 <= '0';					--	******						
 				end if;                  
--;----------------------------------------------------------------------------
--;----------------------------------------------------------------------------
				if DowncounterStartBit = '1' then
					TestSig_00 <= '0';				
				elsif DowncounterStartBit = '0' and intINintern = '1' then
					TestSig_00 <= '1';				
			   end if;
--;----------------------------------------------------------------------------
--;----------------------------------------------------------------------------
-- FIN_FB00 = '1' when no FIN_internB is required

				if FIN_internA = '1' and FIN_signalack = '0' then
					
							if FINcounter_value = FINcounterEnd and FIN_FB00 = '0' then		-- if counter=end and FinB=0 (output required)
								FIN_internB <= '0';
								FINcounter_value  <= FINcounterZero;
								FIN_FB00   <= '1';								
					
							elsif FIN_FB00 = '0' then													-- if counter=!end and FinB=0 (output required)
								FINcounter_value <= FINcounter_value + 1;
								FIN_internB <= '1';
								FIN_FB00   <= '0';							
							end if;

				elsif FIN_internB = '1' and FIN_signalack = '1' then						-- clear FinB (output required) if ackd

							FIN_internB <= '0';
							FINcounter_value  <= FINcounterZero;
							FIN_FB00   <= '1';

				elsif FIN_internA = '0' and FIN_FB00 = '1' then								-- if no FinA then no FinB, clear FeedB, clear ack

							FINcounter_value  <= FINcounterZero;
							FIN_internB <= '0';
							FIN_FB00 <= '0';
							FIN_signalack <= '0';
				end if;					
--;----------------------------------------------------------------------------



----------------------------------------------------------------------------------------------------
-- address   read value                           write operation
-- --------- ------------------------------------ -------------------------------------
-- base+0    status register                      set status register  
-- base+1      (unused)                           perform operation according to value written
-- base+2      (unused)                             (no operation)
-- base+3      (unused)                             (no operation)
-- base+4    muxed register value (low byte)      update muxed register value
-- base+5    muxed register value                 update muxed register value
-- base+6    muxed register value                 update muxed register value
-- base+7    muxed register value (high byte)     update muxed register value
--
--
-- operation values (for writes to base+1):
--   00 -- acknowledge FIN_signal (downcounter got to zero)
--   01 -- reset upcounter value to zero
--   02 -- update latched value from upcounter value
--   03 -- reset downcounter
--   04 -- load downcounter start value with (downcounter_startB - upcounter_value) 
--   05 -- DowncounterStartBit Set
--   06 -- DowncounterStartBit Clear
--   10 -- set register mux select to upcounter current
--   11 -- set register mux select to upcounter latched
--   12 -- set register mux select to downcounter current
--   13 -- set register mux select to downcountre reset
--
--
-- control/status register layout (for r/w to base+0):
--   bits 0, 1, -- register mux select (controls which register is visible in registers at base+4 through base+7):
--        0  0  downcounter current value
--        0  1  downcounter reset value
--        1  0  upcounter current value
--        1  1  upcounter latched value
--     (bits 2, 3, 4, 5 are currently unused)
--   bit 6 -- countdown timer interrupt enable (0=disable, 1=enable)
--   bit 7 -- interrupt flag (0=no interrupt, 1=one or interrupts occurred but not yet acknowledged)
----------------------------------------------------------------------------------------------------

                if enable = '1' and req_write = '1' then  -- enable = cs (active high), reg_write = WriteStrobe (active high).
                    if cpu_address = "000" then  -- (base+0)
                    --    interrupt_signal <= data_in(7);
                    --    interrupt_enable <= data_in(6);
                        regmux_select <= data_in(1 downto 0);
								
                    elsif cpu_address = "001" then  -- (base+1) write value to status register and do operation accoring to value written
                        case data_in is
                            when "00000000" => FIN_signalack <= '1';
                            when "00000001" => upcounter_value <= (others => '0');
                            when "00000010" => upcounter_latch <= upcounter_value;
                            when "00000011" => downcounter_value <= downcounter_startB;
                            when "00000100" => downcounter_startB <= (downcounter_start - upcounter_value);									 		
	                         when "00000101" => DowncounterStartBit <= '1';										
	                         when "00000110" => DowncounterStartBit <= '0';												
											
                            when "00010000" => regmux_select <= "00";
                            when "00010001" => regmux_select <= "01";
                            when "00010010" => regmux_select <= "10";
                            when "00010011" => regmux_select <= "11";
                            when others =>
                        end case;
								
                    elsif cpu_address(2) = '1' then -- (base+4, +5, +5, +7
                        case regmux_select is
                            when "00" => downcounter_value <= unsigned(regmux_updated);
                            when "01" => downcounter_start <= unsigned(regmux_updated);
                            when "10" => upcounter_value   <= unsigned(regmux_updated);
                            when "11" => upcounter_latch   <= unsigned(regmux_updated);									 
                            when others =>
                        end case;
                    end if; 
                end if;
					 
        end if;					    
    end process;
end Behavioral;

