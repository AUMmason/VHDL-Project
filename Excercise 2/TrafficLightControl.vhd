library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std;

entity TrafficLightControl is
  -- Generic interface according to specification
  generic (
    GreenPhaseTime : time;
    NightModeStart : time; -- Minutes passed since 00:00
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
end entity TrafficLightControl;

architecture rtl of TrafficLightControl is
  -- Internal Signals
  signal ENABLE_reg                                          : std_logic; 
  signal RUN_NS, RUN_OW, DISABLE                             : std_logic;
  signal PEDESTRIAN_YELLOW_NS, PEDESTRIAN_YELLOW_OW          : std_logic; -- this signal is not used for pedestrian lights and is always '0'
  signal NS_PED_RED_reg, NS_PED_GREEN_reg                    : std_logic;   
  signal OW_PED_RED_reg, OW_PED_GREEN_reg                    : std_logic; 
  signal NS_CAR_RED_reg, NS_CAR_YELLOW_reg, NS_CAR_GREEN_reg : std_logic;
  signal OW_CAR_RED_reg, OW_CAR_YELLOW_reg, OW_CAR_GREEN_reg : std_logic;

  -- Values according to legal requirements
  constant YellowHoldTime : time    := 2000 ms;
  constant GreenBlinkTime : time    := 1000 ms; -- Bright and Dark Phase together
  constant MaxGreenBlinks : integer := 4;

  -- Clock Setup
  signal   CLK            : std_logic  := '0';
  constant ClockFrequency : integer := 50; -- Hz
  constant ClockPeriod    : time    := 1000 ms / ClockFrequency;

  -- Light Timing Signals
  signal TIMER_LIMIT, TIMER_MEASURED : time := 0 ms;
  signal TIMER_RESET, TIMER_RESET_DONE : std_logic := '0';
  signal PHASE_ENDED : std_logic := '0';

  -- State Machine
  type ControlStates is (OFF, NORTH_SOUTH, EAST_WEST, NORTH_SOUTH_END, EAST_WEST_END);
  signal STATE_CURRENT : ControlStates := OFF;
  signal STATE_NEXT    : ControlStates;

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

  component Timer is
    generic (
      ClockPeriod : time
    );
    port (
      signal CLK, RESET : in std_logic;
      signal LIMIT : in time;
      signal MEASURED : out time;
      signal RESET_DONE : out std_logic
    );
  end component Timer;
begin
  -- Concurrent Logic 
  CLK <= not CLK after ClockPeriod / 2;
  TIMER_LIMIT <= GreenPhaseTime;

  RUN_NS <= '1' when STATE_CURRENT = NORTH_SOUTH else '0';
  RUN_OW <= '1' when STATE_CURRENT = EAST_WEST else '0';
  DISABLE <= '1' when STATE_CURRENT = OFF else '0';

  -- Output Registration

  NS_CAR_GREEN <= NS_CAR_GREEN_reg;
  NS_CAR_YELLOW <= NS_CAR_YELLOW_reg;
  NS_CAR_RED <= NS_CAR_RED_reg;

  OW_CAR_GREEN <= OW_CAR_GREEN_reg;
  OW_CAR_YELLOW <= OW_CAR_YELLOW_reg;
  OW_CAR_RED <= OW_CAR_RED_reg;

  NS_PED_GREEN <= NS_PED_GREEN_reg;
  NS_PED_RED <= NS_PED_RED_reg;

  OW_PED_GREEN <= OW_PED_GREEN_reg;
  OW_PED_RED <= OW_PED_RED_reg;

  CTL_TIMER : Timer generic map (
    ClockPeriod
  ) port map (
    CLK, TIMER_RESET, TIMER_LIMIT, TIMER_MEASURED, TIMER_RESET_DONE
  );

  TL_PED_NS : entity work.TrafficLight(PedestrianTrafficLight) generic map (
    ClockPeriod, YellowHoldTime, GreenBlinkTime, MaxGreenBlinks
  ) port map (
    CLK, RESET, RUN_NS, DISABLE, NS_PED_GREEN_reg, NS_PED_RED_reg, PEDESTRIAN_YELLOW_NS
  );

  TL_CAR_NS : entity work.TrafficLight(CarTrafficLight) generic map (
    ClockPeriod, YellowHoldTime, GreenBlinkTime, MaxGreenBlinks
  ) port map (
    CLK, RESET, RUN_NS, DISABLE, NS_CAR_GREEN_reg, NS_CAR_RED_reg, NS_CAR_YELLOW_reg
  );

  TL_PED_OW : entity work.TrafficLight(PedestrianTrafficLight) generic map (
    ClockPeriod, YellowHoldTime, GreenBlinkTime, MaxGreenBlinks
  ) port map (
    CLK, RESET, RUN_OW, DISABLE, OW_PED_GREEN_reg, OW_PED_RED_reg, PEDESTRIAN_YELLOW_OW
  );

  TL_CAR_OW : entity work.TrafficLight(CarTrafficLight) generic map (
    ClockPeriod, YellowHoldTime, GreenBlinkTime, MaxGreenBlinks
  ) port map (
    CLK, RESET, RUN_OW, DISABLE, OW_CAR_GREEN_reg, OW_CAR_RED_reg, OW_CAR_YELLOW_reg
  );

  InputManager: process(CLK, RESET) is
  begin
    if rising_edge(CLK) then
      if TIME_CURRENT < NightModeStart and TIME_CURRENT > NightModeEnd then
        ENABLE_reg <= ENABLE;
      else 
        ENABLE_reg <= '0';
      end if;
      STATE_CURRENT <= STATE_NEXT;
    elsif RESET = '1' then
      STATE_CURRENT <= OFF;
    end if;
  end process InputManager;

  StateManager: process(ENABLE_reg, STATE_CURRENT, TIMER_MEASURED, NS_CAR_RED_reg, OW_CAR_RED_reg) -- Add Timer
  begin
    STATE_NEXT <= STATE_CURRENT;

    if ENABLE_reg = '1' then
      case STATE_CURRENT is
        when OFF => 
          if PHASE_ENDED = '0' then
            PHASE_ENDED <= '1';
            TIMER_RESET <= not TIMER_RESET;
          elsif PHASE_ENDED = '1' and TIMER_RESET_DONE = '1' then 
            PHASE_ENDED <= '0';            
            STATE_NEXT <= NORTH_SOUTH; -- Bekommt Priorität
          end if;

        when NORTH_SOUTH => 
          if TIMER_MEASURED > TIMER_LIMIT then
            STATE_NEXT <= NORTH_SOUTH_END;
          end if;
        
        when NORTH_SOUTH_END => 
          if NS_CAR_RED_reg'event then  -- only switch when curent lane has red light
            PHASE_ENDED <= '1';
            TIMER_RESET <= not TIMER_RESET;
          elsif PHASE_ENDED = '1' and TIMER_RESET_DONE = '1' then
            PHASE_ENDED <= '0';
            STATE_NEXT <= EAST_WEST;
          end if;

        when EAST_WEST => 
          if TIMER_MEASURED > TIMER_LIMIT then
            STATE_NEXT <= EAST_WEST_END;
          end if;

          when EAST_WEST_END => 
          if OW_CAR_RED_reg'event then
            PHASE_ENDED <= '1';
            TIMER_RESET <= not TIMER_RESET;
          elsif PHASE_ENDED = '1' and TIMER_RESET_DONE = '1' then
            PHASE_ENDED <= '0';
            STATE_NEXT <= NORTH_SOUTH;
          end if;
        
        when others => 
          PHASE_ENDED <= '0';
          STATE_NEXT <= OFF;
      end case;
    else
      -- CHECK if any trafficlight still has outputs on red or green
      PHASE_ENDED <= '0';
      STATE_NEXT <= OFF;
    end if;
  end process StateManager;
  
end architecture rtl;