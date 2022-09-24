library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TimeCounter_Tb is
end entity TimeCounter_Tb;

architecture stimuli of TimeCounter_Tb is
  constant Test_Limit : time := 2500 ms;
  
  constant ClockFrequency : integer := 20; -- Hz
  constant ClockPeriod : time := 1000 ms / ClockFrequency;

  signal CLK_Tb, RESET_Tb : std_logic := '0';
  signal TIME_RESULT : time := 0 ms;

  component TimeCounter is
    generic (
      ClockPeriod : time;
      Limit : time
    );
    port (
      signal CLK, RESET : in std_logic;
      signal MILLISECONDS : out time
    );
  end component TimeCounter;

begin
  
  CLK_Tb <= not CLK_Tb after ClockPeriod / 2;
  
  CNT_1 : TimeCounter generic map (
    ClockPeriod, Test_Limit
  ) port map (
    CLK_Tb, RESET_Tb, TIME_RESULT
  );
  
  Stimuli : process is
  begin
    
    wait for 800 ms;

    report time'image(TIME_RESULT);
    
    wait for 4000 ms;

    report time'image(TIME_RESULT);

    wait for 1000 ms;

    RESET_Tb <= '1';
    report "Reset!";

    wait for 100 ms;

    RESET_Tb <= '0';

    wait for 900 ms;

    report time'image(TIME_RESULT);

    wait for 500 ms;

    report time'image(TIME_RESULT);

    wait for 4000 ms;

    report time'image(TIME_RESULT);

  end process;

end architecture stimuli;