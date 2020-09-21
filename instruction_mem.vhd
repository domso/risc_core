library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use types.all;

entity instruction_mem is
    generic(
        num_words : integer := 256
    );
    port(
        clk : in std_logic;
        n_rst : in std_logic;
        
        pc : in std_logic_vector(31 downto 0);
        instruction : out std_logic_vector(31 downto 0);
    );
end entity;

architecture behaviour of instruction_mem is
    signal mem : std_logic_vector_vector(num_words - 1 downto 0)(31 downto 0) := (others => (others => '0'));
    
begin
    process(all)
        variable addr : integer;
    begin
        if rising_edge(clk) then
            if n_rst = '0' then
                instruction <= (others => '0');
            else            
                addr := to_integer(unsigned(pc srl 2));
            
                if addr < num_words then
                    instruction <= mem(addr);
                else
                    instruction <= (others => '0');
                end if;
            end if;
        end if;
    end process;
end architecture;
