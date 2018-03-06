library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.utils.all;

entity dwt_1 is
    Generic ( WIDTH    : positive := 16;
              SYMBOLS  : positive := 128 );
    Port (    clk, rst : in  STD_LOGIC;
              valid_in : in  BOOLEAN;
              a        : in  SIGNED(WIDTH-1 downto 0); -- input column
              s, d     : out SIGNED(WIDTH-1 downto 0) -- output smoothness and detail
              );
end dwt_1;

architecture logic of dwt_1 is

signal cnt : NATURAL range 0 to SYMBOLS;
signal cnt_std : STD_LOGIC_VECTOR(log2ceil(SYMBOLS+1) downto 0);

type buff_t is array (0 to 3) of SIGNED(WIDTH-1 downto 0);
signal buff : buff_t;

signal calc_d  : BOOLEAN;

signal d_r, s_r : SIGNED(WIDTH-1 downto 0);

signal sum_of_neighbors : SIGNED(WIDTH downto 0);
signal smoothness : SIGNED(WIDTH downto 0);
signal d_prev : SIGNED(WIDTH-1 downto 0);
signal s_next : SIGNED(WIDTH-1 downto 0);
signal difference : SIGNED(WIDTH downto 0);

type state_t is (INIT, CALC);
    signal state : state_t := INIT;
signal cnt_init : natural range 0 to 3 := 0;

begin

--sum_of_neighbors <= (buff(0)(WIDTH-1) & buff(0)) + (buff(2)(WIDTH-1) & buff(2));
sum_of_neighbors <= (s_next(WIDTH-1) & s_next) + (buff(2)(WIDTH-1) & buff(2));
s_next <= buff(2) when cnt=126 else buff(0); --last smooth

difference <= buff(1) - shift_right(sum_of_neighbors,1);
smoothness <= buff(3) + shift_right((d_prev(WIDTH-1) & d_prev) + (d_r(WIDTH-1) & d_r) + 2,2);

cnt_std <= std_logic_vector(to_unsigned(cnt, cnt_std'length));
calc_d <= cnt_std(0) = '0'; -- Calculate detail on odd numbered counter values;

sync : process (clk, rst, valid_in)
    variable d_left : SIGNED(WIDTH downto 0);
begin
    if (rst = '1') then
        s_r <= to_signed(0,s_r'length);
        d_r <= to_signed(0,d_r'length);
        d_prev <= to_signed(0,d_prev'length);
        buff <= (OTHERS => to_signed(0,buff(0)'length));
        cnt <= 0;
        cnt_init <= 0;
        state <= INIT;
    elsif (rising_edge(clk) and valid_in) then
        -- Shift in data
        buff(0) <= a;
        for i in 1 to buff'high loop
            buff(i) <= buff(i-1);
        end loop;
    
        case state is
        when INIT =>
            if cnt_init = 2 then
                state <= CALC;
                cnt_init <= cnt_init;
            else
                state <= state;
                cnt_init <= cnt_init+1;
            end if;
        when CALC =>
            if calc_d then
                s_r <= s_r;
                d_r <= difference(WIDTH-1 downto 0);
                if cnt = 0 then -- first detail
                    d_prev <= difference(WIDTH-1 downto 0);
                else
                    d_prev <= d_r;
                end if;
            else
                s_r <= smoothness(WIDTH-1 downto 0);
                d_r <= d_r;
            end if;
            if cnt < SYMBOLS-1 then
                cnt <= cnt + 1;
            else
                cnt <= 0;
            end if;
        end case;
    end if;
end process sync;

d <= d_r;
s <= s_r;

end logic;
