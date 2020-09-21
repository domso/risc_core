library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use types.all;

package instruction is
    type t_instruction_type is (R_instr, I_instr, S_instr, B_instr, U_instr, J_instr);

    type t_instruction is record(
        opcode : std_logic_vector(6 downto 0);
        funct3 : std_logic_vector(2 downto 0);
        funct7 : std_logic_vector(6 downto 0);
        
        rd : std_logic_vector(4 downto 0);
        rs1 : std_logic_vector(4 downto 0);
        rs2 : std_logic_vector(4 downto 0);
        
        imm : std_logic_vector(31 downto 0);
                
        illegal : std_logic;
        operation : std_logic_vector(36 downto 0);
    );
    
    type t_instruction_execute_result is record (
        memory_byte_en : std_logic_vector(3 downto 0);
        memory_address : std_logic_vector(31 downto 0);
        memory_wen     : std_logic;
        memory_data    : std_logic_vector(31 downto 0);
        
        register_write_addr : std_logic_vector(4 downto 0);
        register_write_data : std_logic_vector(31 downto 0);
        register_write_en   : std_logic;
        
        branch_en : std_logic;
        branch_pc : std_logic_vector(31 downto 0);
    );
    
    function decode_instruction(instruction_word : std_logic_vector(31 downto 0)) return t_instruction;
    
    function execute_instruction(operation : std_logic_vector; pc: std_logic_vector; imm : std_logic_vector(31 downto 0); register_read_data : std_logic_vector_vector(1 downto 0)(31 downto 0)) return t_instruction_execute_result;  
end package;

package body instruction is
    function decode_instruction_by_type(instruction_word : std_logic_vector(31 downto 0); instruction_type : t_instruction_type) return t_instruction is
        variable result : t_instruction;
    begin
        result.opcode := instruction_word(6 downto 0);
        result.funct3 := instruction_word(14 downto 12);
        result.funct7 := instruction_word(31 downto 25);
        
        result.rd     := instruction_word(11 downto 0);
        result.rs1    := instruction_word(19 downto 15);
        result.rs2    := instruction_word(24 downto 20);
                
        result.imm    := (others => '0');
                                                       
        case instruction_type is
            when R_instr =>              
            when I_instr =>                 
                result.imm(11 downto 0) := instruction_word(31 downto 20);
            when S_instr =>                           
                result.imm(4 downto 0) := instruction_word(11 downto 7);
                result.imm(11 downto 5) := instruction_word(31 downto 25);
            when B_instr =>                
                result.imm(11) := instruction_word(7);
                result.imm(4 downto 1) := instruction_word(11 downto 8);
                
                result.imm(10 downto 5) := instruction_word(30 downto 25);
                result.imm(12) := instruction_word(31);
                
            when U_instr =>                
                result.imm(31 downto 12) := instruction_word(31 downto 12);
            when J_instr =>                
                result.imm(19 downto 12) := instruction_word(19 downto 12);
                
                result.imm(11) := instruction_word(20);
                result.imm(10 downto 1) := instruction_word(30 downto 21);
                result.imm(20) := instruction_word(31);
        end case;
        
        return result;
    end function;
    
    
    function decode_instruction(instruction_word : std_logic_vector(31 downto 0)) return t_instruction is
        variable result : t_instruction;
    begin
        result.illegal := '0';
        result.operation := (others => '0');
        
        case instruction_word(6 downto 0) is
            when "0110111" => --LUI
                result := decode_instruction_by_type(instruction_word, U_instr);
                result.operation(0) := '1';
            when "0010111" => --AUIPC
                result := decode_instruction_by_type(instruction_word, U_instr);
                result.operation(1) := '1';
            when "1101111" => --JAL
                result := decode_instruction_by_type(instruction_word, J_instr);
                result.operation(2) := '1';
            when "1100111" => --JALR
                result := decode_instruction_by_type(instruction_word, I_instr);
                result.operation(3) := '1';
            when "1100011" => 
                result := decode_instruction_by_type(instruction_word, B_instr);
                
                case result.funct3 is
                    when "000" =>--BEQ
                        result.operation(4) := '1';
                    when "001" =>--BNE
                        result.operation(5) := '1';
                    when "100" =>--BLT
                        result.operation(6) := '1';
                    when "101" =>--BGE
                        result.operation(7) := '1';
                    when "110" =>--BLTU
                        result.operation(8) := '1';
                    when "111" =>--BGEU
                        result.operation(9) := '1';
                    when others =>
                end case;
            when "0000011" => 
                result := decode_instruction_by_type(instruction_word, I_instr);
                
                case result.funct3 is
                    when "000" =>--LB
                        result.operation(10) := '1';
                    when "001" =>--LH
                        result.operation(11) := '1';
                    when "010" =>--LW
                        result.operation(12) := '1';
                    when "100" =>--LBU
                        result.operation(13) := '1';
                    when "101" =>--LHU
                        result.operation(14) := '1';
                    when others =>
                end case;
            when "0100011" =>
                result := decode_instruction_by_type(instruction_word, S_instr);
                
                case result.funct3 is
                    when "000" =>--SB
                        result.operation(15) := '1';
                    when "001" =>--SH
                        result.operation(16) := '1';
                    when "010" =>--SW
                        result.operation(17) := '1';
                    when others =>
                end case;
            when "0010011" => --ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
                result := decode_instruction_by_type(instruction_word, I_instr);
                
                case result.funct3 is
                    when "000" => --ADDI
                        result.operation(18) := '1';
                    when "001" => --SLLI
                        result.operation(24) := '1';
                    when "010" => --SLTI
                        result.operation(19) := '1';
                    when "011" => --SLTIU
                        result.operation(20) := '1';
                    when "100" => --XORI
                        result.operation(21) := '1';
                    when "101" => 
                        if result.funct7(5) = '0' then --SRLI
                            result.operation(25) := '1';                        
                        else --SRAI
                            result.operation(26) := '1';                           
                        end if;
                    when "110" => --ORI
                        result.operation(22) := '1';
                    when "111" => --ANDI
                        result.operation(23) := '1';
                    when others =>
                end case;
            when "0110011" => --ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
                result := decode_instruction_by_type(instruction_word, R_instr);
                case result.funct3 is
                    when "000" => 
                        if result.funct7(5) = '0' then --ADD
                            result.operation(27) := '1';                          
                        else --SUB
                            result.operation(28) := '1';                          
                        end if;
                    when "001" => --SLL
                        result.operation(29) := '1';      
                    when "010" => --SLT
                        result.operation(30) := '1';      
                    when "011" => --SLTU
                        result.operation(31) := '1';      
                    when "100" => --XOR
                        result.operation(32) := '1';      
                    when "101" => 
                        if result.funct7(5) = '0' then --SRL
                            result.operation(33) := '1';                              
                        else --SRA
                            result.operation(34) := '1';                              
                        end if;
                    when "110" => --OR
                        result.operation(35) := '1';      
                    when "111" => --AND
                        result.operation(36) := '1';      
                    when others =>
                end case;
            when "0001111" => --FENCE, FENCE.I
                --currently not supported
                result.illegal := '1';                
            when "1110011" => --ECALL, EBREAK, CSRRW, CSRRS, CSRRC, CSRRWI, CSRRSI, CSRRCI
                --currently not supported
                result.illegal := '1';
            when others => result.illegal := '1';
        end case;
        
        return result;
    end function;
    
    
    function execute_instruction(operation : std_logic_vector; pc: std_logic_vector;  imm : std_logic_vector(31 downto 0);   register_read_data : std_logic_vector_vector(1 downto 0)(31 downto 0)) return t_instruction_execute_result is
        variable result : t_instruction_execute_result;
    begin
        result.memory_byte_en := (others => '0');
        result.memory_address := (others => '0');
        result.memory_wen     := '0';
        result.memory_data    := (others => '0');
        
        result.register_write_data := (others => '0');
        result.register_write_en   := '0';
        
        result.branch_en := '0';
        result.branch_pc := (others => '0');
        
        if operation(0) = '1' then
            result.register_write_data := imm;
            result.register_write_en   := '1';
        end if;
        
        if operation(1) = '1' then
            result.register_write_data := std_logic_vector(unsigned(pc) + unsigned(imm));
            result.register_write_en   := '1';
        end if;
        
        if operation(2) = '1' then
            result.register_write_data := std_logic_vector(unsigned(pc) + 4);
            result.register_write_en   := '1';        
            
            result.branch_en := '1';
            result.branch_pc := std_logic_vector(unsigned(pc) + unsigned(imm));
        end if;
        
        if operation(3) = '1' then
            result.register_write_data := std_logic_vector(unsigned(pc) + 4);
            result.register_write_en   := '1';        
            
            result.branch_en := '1';
            result.branch_pc := std_logic_vector(unsigned(pc) + unsigned(imm));
        end if;
        
        if operation(4) = '1' then
            if unsigned(register_read_data(0)) = unsigned(register_read_data(1)) then            
                result.branch_en := '1';
                result.branch_pc := std_logic_vector(unsigned(pc) + unsigned(imm));
            end if;            
        end if;
        
        if operation(5) = '1' then
            if unsigned(register_read_data(0)) /= unsigned(register_read_data(1)) then            
                result.branch_en := '1';
                result.branch_pc := std_logic_vector(unsigned(pc) + unsigned(imm));
            end if;            
        end if;        
        
        if operation(6) = '1' then
            if signed(register_read_data(0)) < signed(register_read_data(1)) then            
                result.branch_en := '1';
                result.branch_pc := std_logic_vector(unsigned(pc) + unsigned(imm));
            end if;            
        end if;
        
        if operation(7) = '1' then
            if signed(register_read_data(0)) >= signed(register_read_data(1)) then            
                result.branch_en := '1';
                result.branch_pc := std_logic_vector(unsigned(pc) + unsigned(imm));
            end if;            
        end if;
        
        if operation(8) = '1' then
            if unsigned(register_read_data(0)) < unsigned(register_read_data(1)) then            
                result.branch_en := '1';
                result.branch_pc := std_logic_vector(unsigned(pc) + unsigned(imm));
            end if;            
        end if;
                
        if operation(9) = '1' then
            if unsigned(register_read_data(0)) >= unsigned(register_read_data(1)) then            
                result.branch_en := '1';
                result.branch_pc := std_logic_vector(unsigned(pc) + unsigned(imm));
            end if;            
        end if;
        
        if unsigned(operation(14 downto 10)) /= 0 then
            result.register_write_en   := '1';
            result.memory_address := std_logic_vector(unsigned(register_read_data(0) + unsigned(imm));
            
            if operation(10) = '1' or operation(13) = '1' then
                if result.memory_address(1 downto 0) = "00" then
                    result.memory_byte_en := "0001";
                elsif result.memory_address(1 downto 0) = "01"
                    result.memory_address(1 downto 0) := "00";
                    result.memory_byte_en := "0010";
                elsif result.memory_address(1 downto 0) = "10"
                    result.memory_address(1 downto 0) := "00";
                    result.memory_byte_en := "0100";
                elsif result.memory_address(1 downto 0) = "11"
                    result.memory_address(1 downto 0) := "00";
                    result.memory_byte_en := "1000";
                end if;
            elsif operation(11) = '1' or operation(14) = '1' then
                if result.memory_address(1) = '0' then
                    result.memory_byte_en := "0011";
                else
                    result.memory_address(0) := '0';
                    result.memory_byte_en := "1100";
                end if;
            else
                result.memory_byte_en := (others => '1');
            end if;
        end if;
        
        if unsigned(operation(17 downto 15) /= 0 then
            result.memory_address := std_logic_vector(unsigned(register_read_data(1) + unsigned(imm));
            result.memory_data := register_read_data(0);
            result.memory_wen := '1';
            
            if operation(15) = '1' then
                if result.memory_address(1 downto 0) = "00" then
                    result.memory_byte_en := "0001";
                elsif result.memory_address(1 downto 0) = "01"
                    result.memory_address(1 downto 0) := "00";
                    result.memory_byte_en := "0010";
                    result.memory_data := result.memory_data sll 8;
                elsif result.memory_address(1 downto 0) = "10"
                    result.memory_address(1 downto 0) := "00";
                    result.memory_byte_en := "0100";
                    result.memory_data := result.memory_data sll 16;
                elsif result.memory_address(1 downto 0) = "11"
                    result.memory_address(1 downto 0) := "00";
                    result.memory_byte_en := "1000";
                    result.memory_data := result.memory_data sll 24;
                end if;
            elsif operation(16) = '1' then
                if result.memory_address(1) = '0' then
                    result.memory_byte_en := "0011";
                else
                    result.memory_address(0) := '0';
                    result.memory_data := result.memory_data sll 16;
                    result.memory_byte_en := "1100";
                end if;
            else
                result.memory_byte_en := (others => '1');
            end if;        
        end if;
        
        if unsigned(operation(36 downto 18) /= 0 then
            result.register_write_en   := '1';
            
            if operation(18) = '1' then
                result.register_write_data := std_logic_vector(unsigned(register_read_data(0)) + unsigned(imm));
            elsif operation(19) = '1' then
                if signed(register_read_data(0)) < signed(imm) then
                    result.register_write_data(0) := '1';
                end if;
            elsif operation(20) = '1' then
                if unsigned(register_read_data(0)) < unsigned(imm) then
                    result.register_write_data(0) := '1';
                end if;
            elsif operation(21) = '1' then
                result.register_write_data := register_read_data(0) xor imm;
            elsif operation(22) = '1' then
                result.register_write_data := register_read_data(0) or imm;
            elsif operation(23) = '1' then
                result.register_write_data := register_read_data(0) and imm;
            elsif operation(24) = '1' then
                result.register_write_data := register_read_data(0) sll to_integer(unsigned(imm(4 downto 0)));
            elsif operation(25) = '1' then
                result.register_write_data := register_read_data(0) srl to_integer(unsigned(imm(4 downto 0)));
            elsif operation(26) = '1' then
                result.register_write_data := register_read_data(0) sra to_integer(unsigned(imm(4 downto 0)));
            elsif operation(27) = '1' then
                result.register_write_data := std_logic_vector(unsigned(register_read_data(0)) + unsigned(register_read_data(1)));
            elsif operation(28) = '1' then
                result.register_write_data := std_logic_vector(unsigned(register_read_data(0)) - unsigned(register_read_data(1)));
            elsif operation(29) = '1' then
                result.register_write_data := register_read_data(0) sll to_integer(unsigned(register_read_data(1)));
            elsif operation(30) = '1' then
                if signed(register_read_data(0)) < signed(register_read_data(1)) then
                    result.register_write_data(0) := '1';
                end if;
            elsif operation(31) = '1' then
                if unsigned(register_read_data(0)) < unsigned(register_read_data(1)) then
                    result.register_write_data(0) := '1';
                end if;
            elsif operation(32) = '1' then
                result.register_write_data := register_read_data(0) xor register_read_data(1);
            elsif operation(33) = '1' then
                result.register_write_data := register_read_data(0) srl register_read_data(1);
            elsif operation(34) = '1' then
                result.register_write_data := register_read_data(0) sra register_read_data(1);
            elsif operation(35) = '1' then
                result.register_write_data := register_read_data(0) or register_read_data(1);
            elsif operation(36) = '1' then
                result.register_write_data := register_read_data(0) and register_read_data(1);
            end if;
        end if;
        
    end function;
end package;
