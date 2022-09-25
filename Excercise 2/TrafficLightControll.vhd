library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std;

entity TrafficLightControll is
  -- Generic interface according to specification
  generic (
    GreenPhaseTime : time;
    NightModeStart : time;
    NightModeEnd : time
  );
  port (
    signal CLK, RESET, RUN, DISABLE : in std_logic;
    -- Signals for Pedestrian Traffic Lights
    signal NS_PED_RED, NS_PED_GREEN : out std_logic;   
    signal OW_PED_RED, OW_PED_GREEN : out std_logic; 
    -- Signals for Car Traffic Lights
    signal NS_CAR_RED, NS_CAR_YELLOW, NS_CAR_GREEN : out std_logic;
    signal OW_CAR_RED, OW_CAR_YELLOW, OW_CAR_GREEN : out std_logic
  );
end entity TrafficLightControll;

architecture rtl of TrafficLightControll is
  -- Internal Signals
  signal RUN_reg, DISABLE_reg : std_logic; 
  signal PEDESTRIAN_YELLOW    : std_logic; -- this signal is not used for pedestrian lights and is always '0'
  
  -- Values according to legal requirements
  constant YellowHoldTime : time    := 2000 ms;
  constant GreenBlinkTime : time    := 500 ms;
  constant MaxGreenBlinks : integer := 4;

  -- Clock Setup
  constant ClockFrequency : integer := 50; -- Hz (later 100)
  constant ClockPeriod    : time    := 1000 ms / ClockFrequency;

  component TrafficLight is 
    generic (
      ClockPeriod    : time;
      YellowHoldTime : time;     -- 2 Seconds
      GreenBlinkTime : time;     -- Time for Bright- and Darkphase for end of Green phase
      MaxGreenBlinks : integer   -- Maximum Times
      );
    port (
      signal CLK, RESET, RUN, DISABLE : in std_logic;
      signal L_GREEN, L_RED, L_YELLOW : out std_logic
    );
  end component;
begin
  TL_PED_NS : entity work.TrafficLight(CarTrafficLight) generic map (
    ClockPeriod, YellowHoldTime, GreenBlinkTime, MaxGreenBlinks
  ) port map (
    CLK, RESET, RUN_reg, DISABLE_reg, NS_PED_GREEN, NS_PED_RED, PEDESTRIAN_YELLOW
  );
    
  InputManager: process(CLK, RESET) is
  begin
    if rising_edge(CLK) then
      RUN_reg <= RUN;
      DISABLE_reg <= RUN;
    elsif RESET = '1' then
      --do something
    end if;
  end process InputManager;

  
end architecture rtl;