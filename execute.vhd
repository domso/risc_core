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
        register_read_addr     : in std_logic_vector_vector(1 downto 0)(31 downto 0);             
        register_write_addr     : in std_logic_vector(31 downto 0); 
        
        fwd_register_write_addr : in std_logic_vector(4 downto 0);
        fwd_register_write_data : in std_logic_vector(31 downto 0);
        fwd_register_write_en   : in std_logic;
        
        memory_byte_en : out std_logic_vector(3 downto 0);
        memory_address : out std_logic_vector(31 downto 0);
        memory_wen     : out std_logic;
        memory_data    : out std_logic_vector(31 downto 0);
        memory_sign_extend  : out std_logic;
        
        register_write_addr : out std_logic_vector(4 downto 0);
        register_write_data : out std_logic_vector(31 downto 0);
        register_write_en   : out std_logic;
    );
end entity;

architecture behaviour of execute is
begin
    process(all)
        variable instruction_execute_result : t_instruction_execute_result;
        variable selected_read_data     : std_logic_vector_vector(1 downto 0)(31 downto 0); 
    begin
        if rising_edge(clk) then
            if n_rst = '0' then
                memory_byte_en <= (others => '0');
                memory_address <= (others => '0');
                memory_wen     <= '0';
                memory_data    <= (others => '0');
                memory_sign_extend  <= '0';
                
                register_write_addr <= (others => '0');
                register_write_data <= (others => '0');
                register_write_en   <= '0';
            else
                if fwd_register_write_en = '1' and fwd_register_write_addr = register_read_addr(0) and fwd_register_write_addr = register_read_addr(1) then
                    selected_read_data(0) := fwd_register_write_data;        
                    selected_read_data(1) := fwd_register_write_data;
                elsif fwd_register_write_en = '1' and fwd_register_write_addr = register_read_addr(0) and fwd_register_write_addr /= register_read_addr(1) then
                    selected_read_data(0) := fwd_register_write_data;        
                    selected_read_data(1) := register_read_data(1);
                elsif fwd_register_write_en = '1' and fwd_register_write_addr /= register_read_addr(0) and fwd_register_write_addr = register_read_addr(1) then
                    selected_read_data(0) := register_read_data(0);        
                    selected_read_data(1) := fwd_register_write_data;                
                else
                    selected_read_data(0) := register_read_data(0);        
                    selected_read_data(1) := register_read_data(1);        
                end if;
            
                instruction_execute_result := execute_instruction(
                    operation,
                    pc,
                    register_read_data(0),
                    selected_read_data
                );                
                
                memory_byte_en <= instruction_execute_result.memory_byte_en;
                memory_address <= instruction_execute_result.memory_address;
                memory_wen     <= instruction_execute_result.memory_wen;
                memory_data    <= instruction_execute_result.memory_data;
                memory_sign_extend  <= instruction_execute_result.memory_sign_extend;
                
                register_write_addr <= register_write_addr;
                register_write_data <= instruction_execute_result.register_read_data;
                register_write_en   <= instruction_execute_result.register_write_en;
            end if;
        end if;
    end process;
end architecture;

