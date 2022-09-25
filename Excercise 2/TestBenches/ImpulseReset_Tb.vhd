library ieee;
use ieee.std_logic_1164.all;

entity ImpulseReset_Tb is
end entity ImpulseReset_Tb;

architecture stimuli of ImpulseReset_Tb is
  component ImpulseReset is
    port (
      signal CLK, RESET_IN : in std_logic;
      signal RESET_OUT : out std_logic
    );
  end component ImpulseReset;

  signal CLK, RESET, RESULT : std_logic := '0';
begin
  I_RST : ImpulseReset port map (CLK, RESET, RESULT);


  CLK <= not CLK after 5 ns;

  process is
  begin
    RESET <= '0';

    wait for 30 ns;

    RESET <= not RESET;

    wait for 60 ns;

    RESET <= not RESET;

    wait for 100 ns;
    wait;
  end process;
  
  
  
end architecture stimuli;