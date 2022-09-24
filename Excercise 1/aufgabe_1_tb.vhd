entity SwitchDebounceTb is
end entity;

architecture stimuli of SwitchDebounceTb is
    component SwitchDebounce is
        generic (MAX_TIME : integer);
        port (
            PRESSED, CLK : in bit;
            S_OUT : out bit
        );
    end component;
    signal TB_PRESSED, TB_CLK, TB_S_OUT : bit;
    signal maxtime : integer := 30;
begin
    
    SWDB : SwitchDebounce generic map(maxtime) port map(TB_PRESSED, TB_CLK, TB_S_OUT);
    
    TB_CLK <= not TB_CLK after 5 ns;
    
    Sim : process is
    begin
        TB_PRESSED <= '0';

        wait for 50 ns;

        TB_PRESSED <= '1';

        wait for 10 ns;

        TB_PRESSED <= '0';

        wait for 20 ns;

        TB_PRESSED <= '1';

        wait for 40 ns;

        wait;
        end process;
end architecture;
