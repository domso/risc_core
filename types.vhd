library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package types is
    type std_logic_vector_vector is array (natural range <>) of std_logic_vector;
end package;
