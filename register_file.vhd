library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use types.all;

entity register_file is
    port(
        clk : in std_logic;
        n_rst : in std_logic;
        
        read_addr : in std_logic_vector_vector(1 downto 0)(4 downto 0);
        read_en   : in std_logic_vector(1 downto 0);
        
        write_addr : in std_logic_vector(4 downto 0);
        write_data : in std_logic_vector(31 downto 0);
        write_en   : in std_logic;
        
        read_data : out std_logic_vector_vector(1 downto 0)(31 downto 0);
        read_data_en : out std_logic_vector(1 downto 0);
    );
end entity;

architecture behaviour of register_file is
    type t_regs is array (natural range <>) of std_logic_vector;
    signal regs : t_regs(31 downto 0)(31 downto 0) := (others => (others => '0'));
begin
    regs(0) <= (others => '0');

    process(all)
    begin
        if rising_edge(clk) then
            if n_rst = '0' then
                read_data <= (others => (others => '0'));
                read_data_en <= (others => '0');
            else
                read_data <= (others => (others => '0'));
                read_data_en <= (others => '0');
                
                if write_en = '1' and unsigned(write_addr) /= 0 then
                    regs(to_integer(unsigned(write_addr))) <= write_data;
                end if;
                
                for i in 0 to 1 loop
                    if read_en(i) = '1' then
                        if write_en = '1' and read_addr(i) = write_addr then
                            read_data(i) <= write_data;
                        else
                            read_data(i) <= regs(to_integer(unsigned(read_addr(i))));
                        end if;
                        
                        read_data_en(i) <= '1';
                    end if;
                end loop;
            end if;
        end if;
    end process;
end architecture;
