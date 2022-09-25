library IEEE;
use IEEE.std_logic_1164.all;

entity ImpulseReset is
  port (
    signal CLK, RESET_IN : in std_logic;
    signal RESET_OUT : out std_logic 
  );
end entity ImpulseReset;

architecture rtl of ImpulseReset is
  signal REG0, REG1, REG2 : std_logic := '0';
begin
  
  process (CLK, RESET_IN) is
  begin
    if RESET_IN'event then
      REG0 <= '1';
      REG1 <= '0';
      REG2 <= '0';
    elsif rising_edge(CLK) then
      REG0 <= '0';
      REG1 <= REG0;
      REG2 <= REG1;
    end if;
  end process;

  RESET_OUT <= '1' when (REG0 = '1' or REG1 = '1' or REG2 = '1') else 
               '0';
  
end architecture rtl;