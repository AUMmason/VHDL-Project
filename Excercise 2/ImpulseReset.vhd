library IEEE;
use IEEE.std_logic_1164.all;

entity ImpulseReset is
  port (
    signal CLK, RESET_IN : in std_logic;
    signal RESET_OUT : out std_logic 
  );
end entity ImpulseReset;

architecture rtl of ImpulseReset is
  signal REG_A, REG_B : std_logic := '0';
begin
  
  process (CLK, RESET_IN) is
  begin
    if RESET_IN'event then
      REG_A <= '1';
      REG_B <= '0';
    elsif rising_edge(CLK) then
      REG_A <= '0';
      REG_B <= REG_A;
    end if;
  end process;

  RESET_OUT <= '1' when (REG_A = '1' or REG_B = '1') else 
               '0';
  
end architecture rtl;