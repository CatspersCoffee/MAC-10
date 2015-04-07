--##############################################################################
-- 
--##############################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- Define the entity outputs as they are connected in the DE-1 development 
-- board. Many of the outputs will be left unused in this demo.
entity MAC_S3E_soc is
    port ( 
        -- ***** Clocks

        CLK_1MHZ       : in std_logic;

        -- ***** User I/O
        FPGA_RESET      : in std_logic;
        LEDS            : out std_logic_vector(3 downto 0);
  

        -- ***** RS-232
        uart_rxd        : in std_logic;
        uart_txd        : out std_logic


        -- ***** GPIO
--        BANK0_IO        : inout std_logic_vector(32 downto 1);
--        BANK1_IO        : inout std_logic_vector(1 downto 1);
--       BANK2_IO        : inout std_logic_vector(2 downto 1)        
	);
end MAC_S3E_soc;

architecture minimal of MAC_S3E_soc is

-- light52 MCU signals ---------------------------------------------------------
signal p0_out :             std_logic_vector(7 downto 0);
signal p1_out :             std_logic_vector(7 downto 0);
signal p2_in :              std_logic_vector(7 downto 0);
signal p3_in :              std_logic_vector(7 downto 0);
signal external_irq :       std_logic_vector(7 downto 0);  
signal reset :              std_logic;
signal clk :                std_logic;


begin

    -- The clock comes from the on-board oscillator. We need no speed so we
    -- won't instantiate a DCM.
    clk <= clk_1MHz;

    -- SOC instantiation 
    mcu: entity work.light52_mcu 
    generic map (
        -- Memory size is defined in package obj_code_pkg...
        CODE_ROM_SIZE => work.obj_code_pkg.XCODE_SIZE,
        XDATA_RAM_SIZE => work.obj_code_pkg.XDATA_SIZE,
        -- ...as is the object code initialization constant.
        OBJ_CODE => work.obj_code_pkg.object_code,
        -- Leave BCD opcodes disabled.
        IMPLEMENT_BCD_INSTRUCTIONS => true,
        -- UART baud rate isn't programmable in run time.
        UART_HARDWIRED => true,
        -- We're using the 16MHz clock of the Avnet S3A board.
        CLOCK_RATE => 1e6
    )
    port map (
        clk             => clk,
        reset           => reset,
            
        txd             => uart_txd,
        rxd             => uart_rxd,
        
        external_irq    => external_irq, 
        
        p0_out          => p0_out,
        p1_out          => p1_out,
        p2_in           => p2_in,
        p3_in           => p3_in
    );

    -- The CPU reset input will be wired straight to the PSoC-controlled
    -- capacitive button labelled 'reset'. This is a recipe for faulty resets
    -- but it will do for the first quick tests.
    reset <= FPGA_RESET;
    
    LEDS <= p0_out(3 downto 0);


  
end minimal;
