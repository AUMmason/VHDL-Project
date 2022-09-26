library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CarTrafficLight_Tb is
end entity CarTrafficLight_Tb;

architecture stimuli of CarTrafficLight_Tb is
  constant ClockFrequency : integer := 50; -- Hz
  constant ClockPeriod : time := 1000 ms / ClockFrequency;

  constant YellowHold : time := 2000 ms;
  constant GreenBlink : time := 1000 ms;
  constant GreenBlinks : integer := 4;

  signal CLK, RESET, RUN, DISABLE, GREEN, RED, YELLOW : std_logic := '0';

  component TrafficLight is 
    generic (
      ClockPeriod : time;
      YellowHoldTime : time;  
      GreenBlinkTime : time; 
      MaxGreenBlinks : integer 
    );
    port (
      signal CLK, RESET, RUN, DISABLE : in std_logic;
      signal L_GREEN, L_RED, L_YELLOW : out std_logic
    );
  end component;
begin
  
  T_LIGHT : entity work.TrafficLight(CarTrafficLight) generic map (
    ClockPeriod, YellowHold, GreenBlink, GreenBlinks
  ) port map (
    CLK, RESET, RUN, DISABLE, GREEN, RED, YELLOW
  );
  
  CLK <= not CLK after ClockPeriod / 2;

  Stimuli : process is
  begin 
    report time'image(ClockPeriod);
    wait for 1000 ms;

    DISABLE <= '1';

    wait for 7000 ms;

    DISABLE <= '0';

    wait for 7000 ms;

    RUN <= '1';

    wait for 8000 ms;

    RUN <= '0';

    wait for 8000 ms;

    RUN <= '1';

    wait for 5000 ms;

    DISABLE <= '1';

    wait for 800 ms;

    DISABLE <= '0';

    wait for 5000 ms;

    RUN <= '0';

    wait for 3000 ms;
    wait;
  end process;
  
end architecture stimuli;