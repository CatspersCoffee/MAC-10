--
--	GPIO vhd
--	Modified 08-04-2015 -> adding higher range ports
--
--
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity gpio is
    port ( clk              : in  std_logic;
           reset            : in  std_logic;
           cpu_address      : in  std_logic_vector(2 downto 0);
           data_in          : in  std_logic_vector(7 downto 0);
           data_out         : out std_logic_vector(7 downto 0);
           enable           : in  std_logic;
           read_notwrite    : in  std_logic;
           input_pins       : in  std_logic_vector(7 downto 0);
           output_pins_n1      : out std_logic_vector(7 downto 0);			  
           output_pins_n2    : out std_logic_vector(7 downto 0)
    );
end gpio;

architecture Behavioral of gpio is

    signal captured_inputs  : std_logic_vector(7 downto 0);
    signal register_outputs_n1 : std_logic_vector(7 downto 0);	 
    signal register_outputs_n2 : std_logic_vector(7 downto 0) := (others => '1');

begin

    with cpu_address select
        data_out <=
            captured_inputs   when "000",
            register_outputs_n1  when "001",
				register_outputs_n2  when "010",		-- modified AB 09-04-2015
            register_outputs_n1  when others;

    output_pins_n1 <= register_outputs_n1;
	 output_pins_n2 <= register_outputs_n2;

    gpio_proc: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                captured_inputs <= (others => '0');
                register_outputs_n1 <= (others => '1');
                register_outputs_n2 <= (others => '1');					 
            else
                captured_inputs <= input_pins;

                if enable = '1' and read_notwrite = '0' then 
                    case cpu_address is
                        when "000" => -- no change
                        when "001" => register_outputs_n1 <= data_in;
                        when "010" => register_outputs_n2 <= data_in;		-- modified AB 09-04-2015								
                        when others => -- no change
                    end case;
                end if;
            end if;
        end if;
    end process;
end Behavioral;

