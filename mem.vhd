library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use types.all;

entity mem is
    generic(
        num_words : integer := 256
    );
    port(
        clk : in std_logic;
        n_rst : in std_logic;
        
        memory_byte_en : in std_logic_vector(3 downto 0);
        memory_address : in std_logic_vector(31 downto 0);
        memory_wen     : in std_logic;
        memory_data    : in std_logic_vector(31 downto 0);
        memory_sign_extend  : in std_logic;
        
        register_write_addr : in std_logic_vector(4 downto 0);
        register_write_data : in std_logic_vector(31 downto 0);
        register_write_en   : in std_logic;
        
        write_back_addr : out std_logic_vector(4 downto 0);
        write_back_data : out std_logic_vector(31 downto 0);
        write_back_en   : out std_logic
    );
end entity;

architecture behaviour of mem is
    signal reg_mem : std_logic_vector_vector(num_words - 1 downto 0)(31 downto 0);
    signal scaled_addr : std_logic_vector(29 downto 0);
    
    function extend_sign(word : std_logic_vector; mask : std_logic_vector) return std_logic_vector is
        variable result : std_logic_vector(31 downto 0) := word
        variable one_vec : std_logic_vector(31 downto 0) := (others => '1');
    begin
    
        if mask(3 downto 2) = "01" and word(23) = '1' then
            result := one_vec(7 downto 0) & result(23 downto 0);
        elsif mask(3 downto 1) = "001" and word(15) = '1' then
            result := one_vec(15 downto 0) & result(15 downto 0);
        elsif mask(3 downto 0) = "0001" and word(7) = '1' then
            result := one_vec(23 downto 0) & result(7 downto 0);
        end if;
        
        return result;
    end function;
begin
    scaled_addr <= memory_address(31 downto 2);

    process(all)
        variable read_word : std_logic_vector(31 downto 0);
    begin
        if rising_edge(clk) then
            if n_rst = '0' then
                write_back_addr <= (others => '0');
                write_back_data <= (others => '0');
                write_back_en   <= '0';
            else
                write_back_addr <= register_write_addr;    
                write_back_data <= (others => '0');
                write_back_en   <= register_write_en;  
                
                if unsigned(memory_byte_en) = 0 then                          
                    write_back_data <= register_write_data;
                else
                    read_word := (others => '0');
                    
                    if unsigned(scaled_addr) < num_words then
                        for i in 0 to 3 loop
                            if memory_byte_en(0) = '1' then
                                if memory_wen = '0' then
                                    read_word((i + 1) * 8 - 1 downto i * 8) <= reg_mem(to_integer(unsigned(scaled_addr)))((i + 1) * 8 - 1 downto i * 8);
                                else
                                    reg_mem(to_integer(unsigned(scaled_addr)))((i + 1) * 8 - 1 downto i * 8) <= register_write_data((i + 1) * 8 - 1 downto i * 8);
                                end if;
                            end if;
                        end loop;
                    end if;
                    
                    if memory_wen = '1' then
                        if memory_sign_extend = '1' then
                            write_back_data <= extend_sign(read_word);
                        else
                            write_back_data <= read_word;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
end architecture;
