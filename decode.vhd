library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use types.all;
use instruction.all;

entity decode is
    port(
        clk : in std_logic;
        n_rst : in std_logic;
                
        instruction_word_en : in std_logic;
        pc_in : in std_logic_vector(31 downto 0);
        instruction_word : in std_logic_vector(31 downto 0);
        
        pc_out : out std_logic_vector;
        instruction_en : out std_logic;
        instruction_op : out std_logic_vector(36 downto 0);
        instruction_data : out std_logic_vector_vector(2 downto 0)(31 downto 0);        
        instruction_write_addr : out std_logic_vector(4 downto 0);          
        instruction_read_addr     : out std_logic_vector_vector(1 downto 0)(31 downto 0);     
        
        register_write_addr : in std_logic_vector(4 downto 0);
        register_write_data : in std_logic_vector(31 downto 0);
        register_write_en   : in std_logic;
    );
end entity;

architecture behaviour of decode is
    signal fwd_decoded_instruction : t_instruction;
begin
            
    process(all
    begin
        fwd_decoded_instruction <= decode_instruction(instruction_word);
    end process;
    
    process(all)
    begin
        if rising_edge(clk) then
            if n_rst = '0' then
                instruction_en <= '0';
                pc_out <= (others => '0');
                
                instruction_op <= (others => '0');
                instruction_data(0) <= (others => '0');
                instruction_write_addr <= (others => '0');
            else           
                if fwd_decoded_instruction.illegal = '0' then
                    instruction_en <= instruction_word_en;
                    pc_out <= pc_in;
                    
                    instruction_op <= fwd_decoded_instruction.operation;
                    instruction_data(0) <= fwd_decoded_instruction.imm;
                    instruction_write_addr <= fwd_decoded_instruction.rd;
                else                
                    instruction_en <= '0';
                    pc_out <= (others => '0');
                    
                    instruction_op <= (others => '0');
                    instruction_data(0) <= (others => '0');
                    instruction_write_addr <= (others => '0');
                end if;
            end if;
        end if;
    end process;
    
    register_file_inst: entity register_file
    port map(
        clk => clk,
        n_rst => n_rst,
        
        read_addr => (fwd_decoded_instruction.rs1, fwd_decoded_instruction.rs2),
        read_en   => (instruction_word_en, instruction_word_en),
                
        write_addr => register_write_addr,
        write_data => register_write_data,
        write_en   => register_write_en,
        
        read_data => instruction_data(2 downto 1),
        read_data_en => open
    );
end architecture;
