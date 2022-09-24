library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TrafficLight_Tb is
end entity TrafficLight_Tb;

architecture stimuli of TrafficLight_Tb is
  constant ClockFrequency : integer := 50; -- Hz
  constant ClockPeriod : time := 1000 ms / ClockFrequency;

  constant YellowHold : time := 2000 ms;
  constant GreenBlink : time := 1000 ms;
  constant GreenBlinks : integer := 4;

  signal CLK, RESET, RUN, DISABLE, GREEN, RED, YELLOW : std_logic := '0';

  component TrafficLight is 
    generic (
      ClockPeriod : time;
      YellowHoldTime : time;     -- 2 Sekunden für das Halten der Grünphase
      MaxGreenBlinks : integer;  -- Maximale Anzahl die Grün Blinken soll
      GreenBlinkTime : time      -- Zeitangabe für Hell und Dunkelphase (Einzelne Phase = / 2) 
    );
    port (
      signal CLK, RESET, RUN, DISABLE : in std_logic;
      signal L_GREEN, L_RED, L_YELLOW : out std_logic
    );
  end component;
begin
  
  T_LIGHT : TrafficLight generic map (
    ClockPeriod, YellowHold, GreenBlinks, GreenBlink
  ) port map (
    CLK, RESET, RUN, DISABLE, GREEN, RED, YELLOW
  );
  
  CLK <= not CLK after ClockPeriod / 2;

  Stimuli : process is
  begin 
    wait for 100 ms;

    DISABLE <= '1';

    wait for 400 ms;

    DISABLE <= '0';

    wait for 400 ms;

    RUN <= '1';

    wait for 400 ms;

    RUN <= '0';

    wait for 400 ms;

    DISABLE <= '1';

    wait for 400 ms;

    wait;
  end process;
  
end architecture stimuli;