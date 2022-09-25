library ieee;
use ieee.std_logic_1164.all;

entity Timer_Tb is
end entity Timer_Tb;

architecture stimuli of Timer_Tb is
  constant ClockFrequency : integer := 50; -- Hz
  constant ClockPeriod : time := 1000 ms / ClockFrequency;

  signal CLK, RESET : std_logic := '0';
  signal LIMIT, MEASURED : time := 0 ms;

  component Timer is
    generic (
      ClockPeriod : time
    );
    port (
      signal CLK, RESET : in std_logic;
      signal LIMIT : in time;
      signal MEASURED : out time
    );
  end component Timer;
begin
  T_1 : Timer generic map(
    ClockPeriod
  ) port map(
    CLK, RESET, LIMIT, MEASURED
  );

  CLK <= not CLK after ClockPeriod / 2;

  Test: process
  begin
    LIMIT <= 400 ms;

    wait for 500 ms;

    RESET <= not RESET;

    wait for 500 ms;

    LIMIT <= 700 ms;

    wait for 500 ms;

    RESET <= not RESET;

    wait for 500 ms;

    LIMIT <= 300 ms;

    wait for 500 ms;
    wait;
  end process Test;


end architecture stimuli;