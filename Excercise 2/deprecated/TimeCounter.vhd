library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TimeCounter is
  generic (
    ClockPeriod : time;
    Limit : time
  );
  port (
    signal CLK, RESET : in std_logic;
    signal MILLISECONDS : out time
  );
end entity TimeCounter;

architecture rtl of TimeCounter is
  signal MILLISECONDS_reg : time := 0 ms;
  signal CLOCK_TICKS : integer := 0;
begin

  MILLISECONDS <= MILLISECONDS_reg;

  process (CLK, RESET) is 
  begin 
    if rising_edge(CLK) and MILLISECONDS_reg < Limit then 
      CLOCK_TICKS <= CLOCK_TICKS + 1;
    elsif rising_edge(RESET) then 
      CLOCK_TICKS <= 0;
    end if;
  end process;
  
  process (CLOCK_TICKS) is 
  begin
    MILLISECONDS_reg <= CLOCK_TICKS * ClockPeriod;
  end process;

  
end architecture rtl;