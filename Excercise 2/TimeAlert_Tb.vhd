library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TimeAlert_Tb is
end entity TimeAlert_Tb;

architecture stimuli of TimeAlert_Tb is  
  constant ClockFrequency : integer := 50; -- Hz
  constant ClockPeriod : time := 1000 ms / ClockFrequency;

  signal CLK_Tb, RESET_Tb : std_logic := '0';
  signal TIME_LIMIT : time; 
  signal SUCCESS : std_logic;

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

  -- Später in ein Package geben
  procedure ResetTimer (
    signal RES : out std_logic;
    constant Period : in time
  ) is
  begin
    RES <= '1';
    wait for Period;
    RES <= '0';
  end procedure;

begin
  
  CLK_Tb <= not CLK_Tb after ClockPeriod / 2;

  CNT : TimeAlert generic map (
    ClockPeriod
  ) port map (
    CLK_Tb, RESET_Tb, TIME_LIMIT, SUCCESS
  );
  
  Stimuli : process is
  begin
    TIME_LIMIT <= 500 ms;

    wait for 600 ms;

    ResetTimer(RESET_Tb, ClockPeriod);

    wait for 300 ms;

    ResetTimer(RESET_Tb, ClockPeriod);

    wait for 580 ms;

    TIME_LIMIT <= 770 ms;

    wait for 900 ms;

    TIME_LIMIT <= 400 ms;

    wait for 200 ms;

    TIME_LIMIT <= 600 ms;

    wait for 800 ms;
    
    wait;
  end process;
  
  
end architecture stimuli;