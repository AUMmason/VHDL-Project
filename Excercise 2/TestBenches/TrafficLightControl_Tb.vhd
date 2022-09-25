library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TrafficLightControl_Tb is
end entity TrafficLightControl_Tb;

architecture stimuli of TrafficLightControl_Tb is
  component TrafficLightControl is
    -- Generic interface according to specification
    generic (
      GreenPhaseTime : time;
      NightModeStart : time;
      NightModeEnd : time
    );
    port (
      signal RESET, ENABLE : in std_logic;
      signal TIME_CURRENT : in time;
      -- Signals for Pedestrian Traffic Lights
      signal NS_PED_RED, NS_PED_GREEN : out std_logic;   
      signal OW_PED_RED, OW_PED_GREEN : out std_logic; 
      -- Signals for Car Traffic Lights
      signal NS_CAR_RED, NS_CAR_YELLOW, NS_CAR_GREEN : out std_logic;
      signal OW_CAR_RED, OW_CAR_YELLOW, OW_CAR_GREEN : out std_logic
    );
  end component TrafficLightControl;

  signal ENABLE_TB, RESET_TB : std_logic := '0';
  signal NS_PED, OW_PED : std_logic_vector (1 downto 0);
  signal NS_CAR, OW_CAR : std_logic_vector (2 downto 0);

  -- Signals for Pedestrian Traffic Lights
  signal NS_PED_RED, NS_PED_GREEN : std_logic;   
  signal OW_PED_RED, OW_PED_GREEN : std_logic; 
  -- Signals for Car Traffic Lights
  signal NS_CAR_RED, NS_CAR_YELLOW, NS_CAR_GREEN : std_logic;
  signal OW_CAR_RED, OW_CAR_YELLOW, OW_CAR_GREEN : std_logic;

  constant GreenPhaseTime : time := 10000 ms;
  constant NightModeStart : time := 22*60 min; --22:00
  constant NightModeEnd   : time := 4*60 min;  --04:00
  signal TIME_CURRENT     : time;

begin
  NS_PED <= (NS_PED_RED, NS_PED_GREEN);
  OW_PED <= (OW_PED_RED, OW_PED_GREEN);
  NS_CAR <= (NS_CAR_RED, NS_CAR_YELLOW, NS_CAR_GREEN);
  OW_CAR <= (OW_CAR_RED, OW_CAR_YELLOW, OW_CAR_GREEN);

  TL_CTL : TrafficLightControl generic map (
    GreenPhaseTime, NightModeStart, NightModeEnd
  ) port map (
    RESET => RESET_TB,
    ENABLE => ENABLE_TB,
    TIME_CURRENT => TIME_CURRENT,
    NS_PED_RED => NS_PED_RED,
    NS_PED_GREEN => NS_PED_GREEN,  
    OW_PED_RED => OW_PED_RED,
    OW_PED_GREEN => OW_PED_GREEN,
    NS_CAR_RED => NS_CAR_RED,
    NS_CAR_YELLOW => NS_CAR_YELLOW,
    NS_CAR_GREEN => NS_CAR_GREEN,
    OW_CAR_RED => OW_CAR_RED,
    OW_CAR_YELLOW => OW_CAR_YELLOW,
    OW_CAR_GREEN => OW_CAR_GREEN
  );

  Stimuli: process is
  begin
    ENABLE_TB <= '1';
    TIME_CURRENT <= 3*60 min;

    wait for 7000 ms;

    TIME_CURRENT <= 7*60 min;

    wait for 43000 ms;

  end process Stimuli;
    
end architecture stimuli;