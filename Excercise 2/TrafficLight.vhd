library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TrafficLight is 
  generic (
    ClockPeriod : time;
    YellowHoldTime : time;     -- 2 Sekunden für das Halten der Grünphase
    GreenBlinkTime : time;      -- Zeitangabe für Hell und Dunkelphase (Einzelne Phase = / 2) 
    MaxGreenBlinks : integer  -- Maximale Anzahl die Grün Blinken soll bei Beendung der Grünphase
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
  signal TIMER_LIMIT, TIMER_MEASURED : time := 0 ms;
  signal TIMER_RESET, TIMER_RESET_DONE : std_logic := '0';
  signal PHASE_ENDED : std_logic := '0';

  -- Import of Timecounter
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
  T_0 : Timer generic map(
    ClockPeriod
  ) port map (
    CLK, TIMER_RESET, TIMER_LIMIT, TIMER_MEASURED, TIMER_RESET_DONE 
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

  StateManager : process (STATE_CURRENT, RUN_reg, DISABLE_reg, TIMER_MEASURED) is 
  begin
    STATE_NEXT <= STATE_CURRENT;

    if DISABLE_reg = '0' then

      case STATE_CURRENT is
        when OFF => 
          if RUN_reg = '0' then
            if unsigned(BLINKED) < MaxGreenBlinks + 1 then -- Warte 0,5 Sekunden 
              if TIMER_MEASURED > TIMER_LIMIT then
                PHASE_ENDED <= '1';
                TIMER_LIMIT <= GreenBlinkTime / 2;
                TIMER_RESET <= not TIMER_RESET;
              elsif PHASE_ENDED = '1' and TIMER_RESET_DONE = '1' then
                PHASE_ENDED <= '0';
                STATE_NEXT <= GREEN;
              end if;
            end if;
          else 
            STATE_NEXT <= YELLOW;
          end if;
  
        when YELLOW => -- Warte für 2 Sekunden
          BLINKED <= "0000"; -- Rest Blink counter for green
          if TIMER_MEASURED > TIMER_LIMIT then
            PHASE_ENDED <= '1';
            TIMER_LIMIT <= GreenBlinkTime / 2;
            TIMER_RESET <= not TIMER_RESET;
          elsif PHASE_ENDED = '1' and TIMER_RESET_DONE = '1' then
            PHASE_ENDED <= '0';
            STATE_NEXT <= RED;
          end if;
  
        when RED => 
          if RUN = '1' then
            if PHASE_ENDED = '0' then
              PHASE_ENDED <= '1';
              TIMER_LIMIT <= YellowHoldTime;
              TIMER_RESET <= not TIMER_RESET;
            elsif PHASE_ENDED = '1' and TIMER_RESET_DONE = '1' then
              PHASE_ENDED <= '0';
              STATE_NEXT <= RED_END;
            end if;            
          end if;
  
        when RED_END => -- Warte für 2 Sekunden (Gelb und Rot leuchten)
          if RUN = '1' then
            if TIMER_MEASURED > TIMER_LIMIT then
              PHASE_ENDED <= '1';
              TIMER_LIMIT <= GreenBlinkTime / 2;
            elsif PHASE_ENDED = '1' then
              PHASE_ENDED <= '0';
              STATE_NEXT <= GREEN;
            end if;
          elsif RUN = '0' then
            STATE_NEXT <= RED;
          end if;
  
        when GREEN => -- Viermal Blinked aufhörend mit Grün (jeweils 0,5 sekunden) 
          if RUN_reg = '0' then
            if unsigned(BLINKED) < MaxGreenBlinks + 1 then
              if RUN_reg'event then 
                TIMER_RESET <= not TIMER_RESET;
              elsif TIMER_MEASURED > TIMER_LIMIT then
                BLINKED <= std_logic_vector(unsigned(BLINKED) + 1);
                PHASE_ENDED <= '1';
                TIMER_LIMIT <= GreenBlinkTime / 2;
                TIMER_RESET <= not TIMER_RESET;
              elsif PHASE_ENDED = '1' and TIMER_RESET_DONE = '1' then
                PHASE_ENDED <= '0';
                STATE_NEXT <= OFF;
              end if;
            else  
              if PHASE_ENDED = '0' then
                PHASE_ENDED <= '1';
                TIMER_LIMIT <= YellowHoldTime;
                TIMER_RESET <= not TIMER_RESET;
              elsif PHASE_ENDED = '1' and TIMER_RESET_DONE = '1' then
                PHASE_ENDED <= '0';
                STATE_NEXT <= YELLOW;
              end if; 
            end if;
          end if;

          -- else bleibt Grün
        when others =>     
          PHASE_ENDED <= '0';
          BLINKED <= std_logic_vector( to_unsigned( MaxGreenBlinks + 1, BLINKED'length));
          STATE_NEXT <= YELLOW;
      end case;

    else -- DISABLED = '1' 
      TIMER_LIMIT <= YellowHoldTime;
      if RUN_reg = '1' then
        BLINKED <= "0000";
      else 
        BLINKED <= std_logic_vector( to_unsigned( MaxGreenBlinks + 1, BLINKED'length));
      end if;

      case STATE_CURRENT is
        when YELLOW => 
          if TIMER_MEASURED > TIMER_LIMIT then
            PHASE_ENDED <= '1';
            TIMER_RESET <= not TIMER_RESET;
          elsif PHASE_ENDED = '1' and TIMER_RESET_DONE = '1' then
            PHASE_ENDED <= '0';
            STATE_NEXT <= OFF;
          end if;  

        when OFF => 
          if TIMER_MEASURED > TIMER_LIMIT then
            PHASE_ENDED <= '1';
            TIMER_RESET <= not TIMER_RESET;
          elsif PHASE_ENDED = '1' and TIMER_RESET_DONE = '1' then
            PHASE_ENDED <= '0';
            STATE_NEXT <= YELLOW;
          end if;  

        when others =>
          STATE_NEXT <= YELLOW;
          PHASE_ENDED <= '0';
          BLINKED <= std_logic_vector( to_unsigned( MaxGreenBlinks + 1, BLINKED'length));
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
  signal TIMER_LIMIT, TIMER_MEASURED : time := 0 ms;
  signal TIMER_RESET, TIMER_RESET_DONE : std_logic := '0';
  signal PHASE_ENDED : std_logic := '0';
  -- Import of Timecounter
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
  T_ALERT : Timer generic map(
    ClockPeriod
  ) port map (
    CLK, TIMER_RESET, TIMER_LIMIT, TIMER_MEASURED, TIMER_RESET_DONE 
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

  StateManager : process (STATE_CURRENT, RUN_reg, DISABLE_reg, TIMER_MEASURED) is
  begin
    STATE_NEXT <= STATE_CURRENT;

    if DISABLE_reg = '0' then
      case STATE_CURRENT is 
        when OFF => 
          if unsigned(BLINKED) < MaxGreenBlinks + 1 then
            if TIMER_MEASURED > TIMER_LIMIT then
              PHASE_ENDED <= '1';
              TIMER_RESET <= not TIMER_RESET;
            elsif PHASE_ENDED = '1' and TIMER_RESET_DONE = '1' then
              PHASE_ENDED <= '0';
              STATE_NEXT <= GREEN;
            end if;
          else 
            STATE_NEXT <= RED;
          end if;

        when RED => 
          if RUN_reg = '1' then
            BLINKED <= "0000";
            STATE_NEXT <= GREEN;
            TIMER_RESET <= not TIMER_RESET;
          end if;

        when GREEN => 
          if RUN_reg = '0' then
            if unsigned(BLINKED) < MaxGreenBlinks + 1 then
              if RUN_reg'event then 
                TIMER_RESET <= not TIMER_RESET;
              elsif TIMER_MEASURED > TIMER_LIMIT then
                BLINKED <= std_logic_vector(unsigned(BLINKED) + 1);
                PHASE_ENDED <= '1';
                TIMER_RESET <= not TIMER_RESET;
              elsif PHASE_ENDED = '1' and TIMER_RESET_DONE = '1' then
                PHASE_ENDED <= '0';
                STATE_NEXT <= OFF;
              end if;
            else  
              STATE_NEXT <= RED;
            end if;
          end if;

        when others => 
          PHASE_ENDED <= '0';
          BLINKED <= std_logic_vector( to_unsigned( MaxGreenBlinks + 1, BLINKED'length));
          STATE_NEXT <= OFF;

      end case;
    else 
      if RUN_reg = '1' then
        BLINKED <= "0000";
      else 
        BLINKED <= std_logic_vector( to_unsigned( MaxGreenBlinks + 1, BLINKED'length));
      end if;
      STATE_NEXT <= OFF;
    end if;
  end process;
  
end architecture PedestrianTrafficLight;