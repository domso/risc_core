library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use types.all;

entity fetch is
    port(
        clk : in std_logic;
        n_rst : in std_logic;
        
        branch_en : in std_logic;
        branch_pc : in std_logic_vector(31 downto 0);
        
        pc : out std_logic_vector(31 downto 0);
        instruction_word : out std_logic_vector(31 downto 0);
        instruction_word_en : out std_logic;
    );
end entity;

architecture behaviour of fetch is
    signal current_pc : std_logic_vector(31 downto 0);
begin
    process(all)
    begin
        if rising_edge(clk) then
            if n_rst = '0' then
                pc <= (others => '0');
                instruction_word_en <= '0';
                
                current_pc <= (others => '0');
            else
                if branch_en = '0' then                    
                    pc <= current_pc;
                    instruction_word_en <= '1';
                
                    current_pc <= std_logic_vector(unsigned(current_pc) + 4);
                else
                    pc <= (others => '0');
                    instruction_word_en <= '0';
                    
                    current_pc <= branch_pc;
                end if;
            end if;
        end if;
    end process;
    
    instruction_mem_inst: entity instruction_mem
    generic map(
        num_words => 256
    )
    port map(
        clk => clk,
        n_rst => n_rst,
        
        pc => current_pc,
        instruction => instruction_word
    );
end architecture;
