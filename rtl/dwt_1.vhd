library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.utils.all;

entity dwt_1 is
    Generic ( WIDTH    : positive := 16;
              SYMBOLS  : positive := 128 );
    Port (    clk, rst : in  STD_LOGIC;
              valid_in : in  BOOLEAN;
              a        : in  SIGNED(WIDTH-1 downto 0);
              s, d     : out SIGNED(WIDTH-1 downto 0)
              );
end dwt_1;

architecture logic of dwt_1 is

-- Control
  type state_t is (INIT, PROCESSING);
signal state : state_t := INIT;
signal cnt_init : natural range 0 to 3 := 0;
signal cnt : NATURAL range 0 to SYMBOLS := 0;
signal d_sel  : BOOLEAN;

-- Data
  type buff_t is array (0 to 3) of SIGNED(WIDTH-1 downto 0);
signal buff : buff_t; -- Input buffer (shiftreg)
signal d_r, s_r : SIGNED(WIDTH-1 downto 0);

signal smooth : SIGNED(WIDTH   downto 0);
signal d_prev : SIGNED(WIDTH-1 downto 0);
signal detail : SIGNED(WIDTH   downto 0);

begin

comb : process(buff, cnt, d_prev, d_r) is
    variable cnt_std : STD_LOGIC_VECTOR(log2ceil(SYMBOLS+1) downto 0);
    variable s_next  : SIGNED(WIDTH-1 downto 0);
    variable s_det   : SIGNED(smooth'Range);
    variable d_sum   : SIGNED(WIDTH downto 0);
    variable s_sum   : SIGNED(WIDTH downto 0);
begin
    if cnt = SYMBOLS-2
        then s_next := buff(2);
        else s_next := buff(0);
    end if;
    d_sum := (s_next(WIDTH-1) & s_next) + (buff(2)(WIDTH-1) & buff(2));
    s_sum := (d_prev(d_prev'High) & d_prev) + (d_r(d_r'High) & d_r) + 2;

    detail <= buff(1) - shift_right(d_sum,1);
    smooth <= buff(3) + shift_right(s_sum,2);

    cnt_std := std_logic_vector(to_unsigned(cnt, cnt_std'length));
    d_sel <= cnt_std(0) = '0'; -- Calculate detail on odd numbered counter values;
end process comb;

sync : process (clk, rst, valid_in)
    variable d_left : SIGNED(WIDTH downto 0);
begin
    if (rst = '1') then
        s_r    <= to_signed(0,    s_r'length);
        d_r    <= to_signed(0,    d_r'length);
        d_prev <= to_signed(0, d_prev'length);
        buff   <= (OTHERS => to_signed(0,buff(0)'length));
        cnt <= 0;
        cnt_init <= 0;
        state <= INIT;
    elsif (rising_edge(clk) and valid_in) then
        -- Shift in data
        buff <= (a & buff(0 to buff'High-1));
    
        case state is

            when INIT =>
                if cnt_init = 2 then
                    state <= PROCESSING;
                    cnt_init <= cnt_init;
                else
                    state <= state;
                    cnt_init <= cnt_init+1;
                end if;

            when PROCESSING =>
                if d_sel then
                    s_r <= s_r;
                    d_r <= detail(WIDTH-1 downto 0);

                    -- The first detail coefficient needs to be stored
                    -- to avoid out of range lookup.
                    if cnt = 0 then -- first detail
                        d_prev <= detail(WIDTH-1 downto 0);
                    else
                        d_prev <= d_r;
                    end if;

                else
                    s_r <= smooth(WIDTH-1 downto 0);
                    d_r <= d_r;
                end if;
                cnt <= (cnt + 1) mod SYMBOLS;

        end case;
    end if;
end process sync;

-- Output
d <= d_r;
s <= s_r;

end logic;
