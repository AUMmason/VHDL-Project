library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- https://miscircuitos.com/power-on-reset-implementation-for-fpga-in-verilog-and-vhdl/

entity Timer is
  generic (
    ClockPeriod : time
  );
  port (
    signal CLK, RESET : in std_logic;
    signal LIMIT : in time;
    signal MEASURED : out time;
    signal RESET_DONE : out std_logic
  );
end entity Timer;

architecture rtl of Timer is
  signal CLOCK_TICKS : integer := 0;
  signal MEASURED_MILLISECONDS : time := 0 ms;
  signal LIMIT_reg : time := 0 ms;
  signal RESET_reg : std_logic;

  component ImpulseReset is
    port (
      signal CLK, RESET_IN : in std_logic;
      signal RESET_OUT : out std_logic 
    );
  end component ImpulseReset;

begin
  I_RST : ImpulseReset port map(CLK, RESET, RESET_reg);

  MEASURED <= MEASURED_MILLISECONDS;
  RESET_DONE <= RESET_reg;

  process (CLK) is 
  begin 
    if rising_edge(CLK) then 
      LIMIT_reg <= LIMIT;
      if (MEASURED_MILLISECONDS <= LIMIT_reg) then
        CLOCK_TICKS <= CLOCK_TICKS + 1;
      end if;
      if LIMIT'event or LIMIT /= LIMIT_reg then
        -- LIMIT_reg <= LIMIT;
        CLOCK_TICKS <= 0;
      end if;

    elsif RESET_reg = '1' then -- Signal also gets reset when counter changes in value
      -- LIMIT_reg <= LIMIT;
      CLOCK_TICKS <= 0;
  end if;
    
  end process;

  process (CLOCK_TICKS) is 
  begin
    MEASURED_MILLISECONDS <= CLOCK_TICKS * ClockPeriod;
  end process;

  
end architecture rtl;