library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Multiplexer_VHDL is
   port
   (
      a, b, c, d, e, f, g, h : in std_logic; 
      Sel : in std_logic_vector(2 downto 0);

      Output : out std_logic
   );
end entity Multiplexer_VHDL;
 
architecture Behavioral of Multiplexer_VHDL is
begin 
   process (a, b, c, d, e, f, g, h, Sel) is
   begin
      case Sel is
         when "000"  => Output <= a;
         when "001"  => Output <= b;
         when "010"  => Output <= c;
         when "011"  => Output <= d;
         when "100"  => Output <= e;
         when "101"  => Output <= f;
         when "110"  => Output <= g;
         when others => Output <= h;
      end case;
   end process;
end architecture Behavioral;