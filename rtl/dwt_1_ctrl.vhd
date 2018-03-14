library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils.all;

entity dwt_1_ctrl is
	generic (
		SYMBOLS : positive
	);
	port (
		clk, rst                      : in  std_logic;
		valid_in                      : in  boolean;
		--valid_out,
		d_sel, first, last : out boolean
	);
end entity dwt_1_ctrl;

architecture rtl of dwt_1_ctrl is
	
	-- Control
	type state_t is (INIT, PROCESSING);
	signal state    : state_t                    := INIT;
	signal cnt_init : natural range 0 to 3       := 0;
	signal cnt      : NATURAL range 0 to SYMBOLS := 0;
	
begin
	
	first <= cnt = 0;
	last  <= cnt = SYMBOLS-2;
	
	comb : process(cnt) is
		variable cnt_std : STD_LOGIC_VECTOR(log2ceil(SYMBOLS+1) downto 0);
	begin
		cnt_std := std_logic_vector(to_unsigned(cnt, cnt_std'length));
		d_sel   <= cnt_std(0) = '0'; -- Calculate detail on odd numbered counter values;
	end process comb;
	
	sync : process (clk, rst, valid_in)
		
	begin
		if (rst = '1') then
			cnt      <= 0;
			cnt_init <= 0;
			state    <= INIT;
			--valid_out <= false;
		elsif (rising_edge(clk) and valid_in) then
			case state is
				when INIT => 
					--valid_out <= false;
					if cnt_init = 2 then
						state    <= PROCESSING;
						cnt_init <= 0;
					else
						state    <= state;
						cnt_init <= cnt_init+1;
					end if;
				when PROCESSING => 
					--valid_out <= true;
					cnt <= (cnt + 1) mod SYMBOLS;
			end case;
		end if;
	end process sync;
	
end architecture rtl;
