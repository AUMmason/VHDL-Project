library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TimeAlert is
  generic (
    ClockPeriod : time
  );
  port (
    signal CLK, RESET : in std_logic;
    signal LIMIT : in time;
    signal FINISHED : out std_logic
  );
end entity TimeAlert;

architecture rtl of TimeAlert is
  signal CLOCK_TICKS : integer := 0;
  signal MEASURED_MILLISECONDS : time := 0 ms;
  signal LIMIT_reg : time := 0 ms;
  signal FINISHED_reg, RESET_reg : std_logic;

  procedure ResetTicks (
    signal RESULT : out std_logic; 
    signal TICKS : out integer
  ) is begin
    RESULT <= '0';
    TICKS <= 0;
  end procedure;
begin

  FINISHED <= FINISHED_reg;

  process (CLK, RESET) is 
  begin 
    if rising_edge(CLK) then 
      LIMIT_reg <= LIMIT;
      if (MEASURED_MILLISECONDS <= LIMIT_reg) then
        CLOCK_TICKS <= CLOCK_TICKS + 1;
      else
        FINISHED_reg <= '1';
      end if;

      if rising_edge(RESET) or falling_edge(RESET) or LIMIT'event or LIMIT /= LIMIT_reg then -- Signal also gets reset when counter changes in value
        ResetTicks(FINISHED_reg, CLOCK_TICKS);
      end if;
    end if;
    
  end process;

  process (CLOCK_TICKS) is 
  begin
    MEASURED_MILLISECONDS <= CLOCK_TICKS * ClockPeriod;
  end process;

  
end architecture rtl;