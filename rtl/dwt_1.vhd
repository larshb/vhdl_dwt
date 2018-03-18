library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.utils.all;

entity dwt_1 is
    Generic ( 
        WIDTH   : positive;
        SYMBOLS : positive
    );
    Port (
        clk, rst     : in  STD_LOGIC;
        valid_in     : in  BOOLEAN;
        x_in         : in  SIGNED(WIDTH-1 downto 0);
        --valid_out    : out BOOLEAN;
        a_out, d_out : out SIGNED(WIDTH-1 downto 0)
    );
end dwt_1;

architecture logic of dwt_1 is
    
    subtype component_t is SIGNED(WIDTH-1 downto 0);
    
    -- Control
    signal d_sel, first, last : boolean;
    
    -- Data
    type x_buff_t is array (0 to 3) of component_t;
    signal x_buff                  : x_buff_t; -- Input buffer (shiftreg)
    signal a_sum, u_dif            : SIGNED(WIDTH downto 0);
    signal u_dif_pre, d_reg, a_reg : component_t;
    
begin
    
    ctrl : entity work.dwt_1_ctrl
        generic map (SYMBOLS => SYMBOLS)
        port map (
            clk       => clk,
            rst       => rst,
            valid_in  => valid_in,
            --valid_out => valid_out,
            d_sel     => d_sel,
            first     => first,
            last      => last
        );
    
    comb : process(x_buff, u_dif_pre, d_reg, last) is
        variable x_e_nxt      : component_t;
        variable p_out, u_sum : SIGNED(WIDTH downto 0);
    begin
        
        if last then
            x_e_nxt := x_buff(2);
        else 
            x_e_nxt := x_buff(0);
        end if;
        
        p_out := (x_e_nxt(WIDTH-1) & x_e_nxt) + (x_buff(2)(WIDTH-1) & x_buff(2));
        u_sum := (u_dif_pre(u_dif_pre'High) & u_dif_pre) + (d_reg(d_reg'High) & d_reg) + 2;
        
        u_dif <= x_buff(1) - shift_right(p_out,1);
        a_sum <= resize(x_buff(3), a_sum'Length) + resize(shift_right(u_sum,2), a_sum'Length); -- Avoid overflow
    end process comb;
    
    sync : process (clk, rst, valid_in)
        variable d_left : SIGNED(WIDTH downto 0);
    begin
        if (rst = '1') then
            a_reg     <= to_signed(0, a_reg'length);
            d_reg     <= to_signed(0, d_reg'length);
            u_dif_pre <= to_signed(0, u_dif_pre'length);
            x_buff    <= (OTHERS => to_signed(0,x_buff(0)'length));
        elsif (rising_edge(clk) and valid_in) then
            -- Shift in data
            x_buff <= (x_in & x_buff(0 to x_buff'High-1));
            if d_sel then --predict
                a_reg <= a_reg;
                d_reg <= u_dif(WIDTH-1 downto 0);
                
                -- The first u_dif coefficient needs to be stored
                -- to avoid out of range lookup.
                if first then -- first u_dif
                    u_dif_pre <= u_dif(WIDTH-1 downto 0);
                else
                    u_dif_pre <= d_reg;
                end if;
                
            else --update
                a_reg <= a_sum(WIDTH-1 downto 0);
                d_reg <= d_reg;
            end if;
        end if;
    end process sync;
    
    -- Output
    d_out <= d_reg;
    a_out <= a_reg;
    
end logic;
