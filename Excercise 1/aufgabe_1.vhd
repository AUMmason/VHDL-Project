entity SwitchDebounce is
    generic (MAX_TIME : integer);
    port (
        PRESSED, CLK : in bit;
        S_OUT : out bit
    );
end entity;

architecture bhv of SwitchDebounce is
    signal PRESSED_reg : bit;
    signal TIMER : unsigned;
begin
    RegisterPress : process (CLK) is
    begin
        if rising_edge(CLK) and CLK = '1' then
            if PRESSED = '1' then
                PRESSED_reg <= '1';
            else
                PRESSED_reg <= '0';
            end if;
        end if;
    end process;

    -- Warten für Zeit MAX_TIME bis signal am output übernommen wird.
    Debounce : process (PRESSED_reg, TIMER) is
    begin
        -- Warten bis die entprellzeit vorbei ist
        if TIMER = MAX_TIME then
            if PRESSED = '1' and PRESSED_reg = '1' then
                S_OUT <= '1';
            else
                S_OUT <= '0';
            end if;
        end if;
    end process;

    TimerProcess : process is
    begin
        if TIMER < MAX_TIME then
            TIMER <= TIMER + 1;
        elsif rising_edge(PRESSED_reg) then
            TIMER <= 0;
        else
            TIMER <= 0;
        end if;
        wait for 1 ns;
    end process;
end architecture;
