library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TrafficLight is 
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
end entity;

architecture CarTrafficLight of TrafficLight is
  signal RESET_reg, RUN_reg, DISABLE_reg : std_logic;
  
  -- Statemachine Internal Signals and Type declaration
  type C_States is (OFF, RED, RED_END, GREEN, YELLOW);
  signal STATE_CURRENT : C_States := OFF;
  signal STATE_NEXT : C_States;
  
  -- Timing Signals
  signal BLINKED : std_logic_vector(3 downto 0) := "0000"; --4 Bits wegen Vorzeichen
  signal TIMER_LIMIT : time := 0 ms;
  signal TIMER_END, TIMER_RESET : std_logic := '0';
  
  -- Import of Timecounter
  component TimeAlert is
    generic (
      ClockPeriod : time
    );
    port (
      signal CLK, RESET : in std_logic;
      signal LIMIT : in time;
      signal FINISHED : out std_logic
    );
  end component TimeAlert;

begin
  T_ALERT : TimeAlert generic map(
    ClockPeriod
  ) port map (
    CLK, TIMER_RESET, TIMER_LIMIT, TIMER_END 
  );

  -- Register Outputs
  L_GREEN <= '1' when STATE_CURRENT = GREEN else '0';
  L_RED <= '1' when (STATE_CURRENT = RED or STATE_CURRENT = RED_END) else '0';
  L_YELLOW <= '1' when (STATE_CURRENT = YELLOW or STATE_CURRENT = RED_END) else '0';

  -- Register Inputs
  InputManager : process (CLK, RESET) is 
  begin 
    if rising_edge(CLK) then
      RUN_reg <= RUN;
      DISABLE_reg <= DISABLE;
      STATE_CURRENT <= STATE_NEXT;
      RESET_reg <= RESET;
      if RESET_reg = '1' then
        STATE_CURRENT <= YELLOW;
      end if;
    end if;
  end process;

  StateManager : process (STATE_CURRENT, RUN_reg, DISABLE_reg) is 
  begin
    STATE_NEXT <= STATE_CURRENT;

    if DISABLE_reg = '0' then

      case STATE_CURRENT is
        when OFF => 
          if RUN_reg = '0' and unsigned(BLINKED) < MaxGreenBlinks + 1 then -- Warte 0,5 Sekunden 
            STATE_NEXT <= GREEN;
          else 
            STATE_NEXT <= YELLOW;
          end if;
  
        when YELLOW => -- Warte für 2 Sekunden
          STATE_NEXT <= RED;
          BLINKED <= "0000"; -- Rest Blink counter for green
  
        when RED => 
          if RUN = '1' then
            STATE_NEXT <= RED_END;
          end if;
  
        when RED_END => -- Warte für 2 Sekunden (Gelb und Rot leuchten)
          if RUN = '1' then
            STATE_NEXT <= GREEN;
          elsif RUN = '0' then
            STATE_NEXT <= RED;
          end if;
  
        when GREEN => -- Viermal Blinked aufhörend mit Grün (jeweils 0,5 sekunden) 
          if RUN = '0' then
            if unsigned(BLINKED) < MaxGreenBlinks then
              BLINKED <= std_logic_vector(unsigned(BLINKED) + 1);
              STATE_NEXT <= OFF;
            else 
              STATE_NEXT <= YELLOW;
            end if;
          end if;
          -- else bleibt Grün
        when others => 
          BLINKED <= std_logic_vector( to_unsigned( MaxGreenBlinks + 1, BLINKED'length));
          STATE_NEXT <= YELLOW;
      end case;

    else -- DISABLED = '1' 
      BLINKED <= std_logic_vector( to_unsigned( MaxGreenBlinks + 1, BLINKED'length));

      case STATE_CURRENT is
        when YELLOW => 
          STATE_NEXT <= OFF;

        when OFF => 
          STATE_NEXT <= YELLOW;

        when others =>
          STATE_NEXT <= YELLOW;
      end case;
    end if;
  end process;

end architecture CarTrafficLight;

architecture PedestrianTrafficLight of TrafficLight is
  signal RESET_reg, RUN_reg, DISABLE_reg : std_logic;
  type P_States is (OFF, GREEN, RED);
  signal STATE_CURRENT : P_States := OFF;
  signal STATE_NEXT : P_States;

  signal BLINKED : std_logic_vector(3 downto 0) := "0000";
  signal TIMER_LIMIT : time := 0 ms;
  signal TIMER_END, TIMER_RESET : std_logic := '0';
  
  -- Import of Timecounter
  component TimeAlert is
    generic (
      ClockPeriod : time
    );
    port (
      signal CLK, RESET : in std_logic;
      signal LIMIT : in time;
      signal FINISHED : out std_logic
    );
  end component TimeAlert;
begin
  T_ALERT : TimeAlert generic map(
    ClockPeriod
  ) port map (
    CLK, TIMER_RESET, TIMER_LIMIT, TIMER_END 
  );

  -- Outputs
  L_GREEN <= '1' when STATE_CURRENT = GREEN else '0';
  L_RED <= '1' when STATE_CURRENT = RED else '0';
  L_YELLOW <= '0'; -- Pedestrian Lights don't have a Yellow light so output is always '0'!
  TIMER_LIMIT <= GreenBlinkTime / 2;


  InputManager : process (CLK, RESET) is 
  begin 
    if rising_edge(CLK) then
      RUN_reg <= RUN;
      DISABLE_reg <= DISABLE;
      RESET_reg <= RESET;
      STATE_CURRENT <= STATE_NEXT;

      if RESET_reg = '1' then
        STATE_CURRENT <= OFF;
      end if;
    end if;
  end process;

  StateManager : process (STATE_CURRENT, RUN_reg, DISABLE_reg) is
  begin
    STATE_NEXT <= STATE_CURRENT;

    if DISABLE_reg = '0' then
      case STATE_CURRENT is 
        when OFF => 
          if unsigned(BLINKED) < MaxGreenBlinks + 1 then
            if TIMER_END = '1' then
              STATE_NEXT <= GREEN;
              TIMER_RESET <= not TIMER_RESET;
            end if;
          else 
            STATE_NEXT <= RED;
          end if;

        when RED => 
          if RUN_reg = '1' then
            BLINKED <= "0000";
            STATE_NEXT <= GREEN;
          end if;

        when GREEN => 
          if RUN_reg = '0' then
            if unsigned(BLINKED) < MaxGreenBlinks then
              if TIMER_END = '1' then
                BLINKED <= std_logic_vector(unsigned(BLINKED) + 1);
                STATE_NEXT <= OFF;              
                TIMER_RESET <= not TIMER_RESET;
              end if;
            else  
              STATE_NEXT <= RED;
            end if;
          end if;

        when others => 
          BLINKED <= std_logic_vector( to_unsigned( MaxGreenBlinks + 1, BLINKED'length));
          STATE_NEXT <= OFF;

      end case;
    else 
      BLINKED <= std_logic_vector( to_unsigned( MaxGreenBlinks + 1, BLINKED'length));
      STATE_NEXT <= OFF;
    end if;
  end process;
  
end architecture PedestrianTrafficLight;