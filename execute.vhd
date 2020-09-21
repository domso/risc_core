library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use types.all;
use instruction.all;

entity execute is
    port(
        clk : in std_logic;
        n_rst : in std_logic;
                        
        operation : in std_logic_vector(36 downto 0);
        pc : in std_logic_vector(31 downto 0);
        register_read_data     : in std_logic_vector_vector(2 downto 0)(31 downto 0);      
        
        fwd_register_write_addr : in std_logic_vector(4 downto 0);
        fwd_register_write_data : in std_logic_vector(31 downto 0);
        fwd_register_write_en   : in std_logic;
        

    );
end entity;

architecture behaviour of execute is
begin
    process(all)
    begin
        if rising_edge(clk) then
            if n_rst = '0' then
            else
            end if;
        end if;
    end process;
end architecture;
