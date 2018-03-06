library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.utils.all;

entity dwt_2 is
	Generic ( WIDTH   : positive := 16;
			  SYMBOLS : positive := 128 );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           valid_i : in STD_LOGIC;
           valid_o : out STD_LOGIC;
           din : in STD_LOGIC_VECTOR (15 downto 0);
           dout : out STD_LOGIC_VECTOR (15 downto 0));
end dwt_2;

architecture logic of dwt_2 is

constant addr_width : positive := log2ceil(SYMBOLS*SYMBOLS);
constant pipe_delay : positive := 4;

signal dwt1h_validi, dwt1v_validi : boolean := false;

subtype pixel_t is SIGNED(WIDTH-1 DOWNTO 0);
signal a, s, d : pixel_t := (others => '0');

subtype addr_t is std_logic_vector(addr_width-1 downto 0);
type addr_array is array (0 to 1) of addr_t;
signal s_addr, d_addr, wr_addr, rd_addr : addr_array;
signal wr_en : boolean := false;
signal wr_data, rd_data : std_logic_vector(WIDTH-1 downto 0);

signal row, col, row0, col0 : unsigned(addr_width/2-1 downto 0);

signal s_d_sel : boolean;
signal first_stage_done, second_stage_done : boolean; -- row-wise then col-wise horizontal 1D-DWT
signal vertical_enable, read_out_enable : boolean;
type vertical_dly_t is array (0 to pipe_delay-1) of boolean;
signal vertical_dly : vertical_dly_t;
signal vertical_rdy : boolean;
signal stream_from_mem : boolean;

--signal dout_select : pixel_t;

signal wr_en_sl : std_logic;

signal a_dwt1 : pixel_t;

begin

a_dwt1 <= signed(rd_data) when stream_from_mem else signed(din);
dwt1h_validi <= valid_i = '1' or vertical_enable;

dwt_1 : 	entity work.dwt_1
			generic map (
				WIDTH => WIDTH,
				SYMBOLS => SYMBOLS
			)
			port map (
				clk => clk,
				rst => rst,
				valid_in => dwt1h_validi,
				a => a_dwt1,
				s => s,
				d => d
			);
			
mem_h :     entity work.mem
            generic map(
                data_width => WIDTH,
                addr_width => addr_width
            )
            port map (
                clk => clk,
                WD1 => wr_data,
                RO1 => rd_data,
                WA1 => wr_addr(0),
                RA1 => rd_addr(1),
                WE1 => to_sl(wr_en),
                WD2 => open,
                RO2 => open,
                WA2 => open,
                RA2 => open,
                WE2 => open
            );

mem_v :     entity work.mem
            generic map(
                data_width => WIDTH,
                addr_width => addr_width
            )
            port map (
                clk => clk,
                WD1 => wr_data,
                RO1 => dout,
                WA1 => wr_addr(0),
                RA1 => rd_addr(1),
                WE1 => to_sl(vertical_rdy),
                WD2 => open,
                RO2 => open,
                WA2 => open,
                RA2 => open,
                WE2 => open
            );
            
row0 <= row;--'0' & row(row'high downto 1); -- can't be halfed on horiz. dwt
col0 <= '0' & col(col'high downto 1); -- unsigned half
s_addr(0) <= std_logic_vector( row0            &  col0);
d_addr(0) <= std_logic_vector( row0            & (col0+SYMBOLS/2));
s_addr(1) <= std_logic_vector( col0            &  row0);
d_addr(1) <= std_logic_vector((col0+SYMBOLS/2) &  row0);

valid_1dh : entity work.pipe generic map (STAGES => pipe_delay+1 ) --Extra cycle delay?
            port map ( clk=>clk, din(0)=>valid_i, dout(0)=>wr_en_sl );
            wr_en <= wr_en_sl='1';

addr_pipe : entity work.pipe
            generic map ( STAGES => pipe_delay )
            port map ( clk=>clk, din=>rd_addr(0), dout=>wr_addr(0) );

first_stage_done <= (col = SYMBOLS-1 and row = SYMBOLS-1);
vertical_rdy <= vertical_dly(vertical_dly'high);
valid_o <= to_sl(read_out_enable);
            
sync: process (clk, rst) begin
    if rst = '1' then
        row <= to_unsigned(0, row'length);
        col <= to_unsigned(0, col'length);
        vertical_enable <= false;
        read_out_enable <= false;
        dwt1v_validi <= false;
        stream_from_mem <= false;
        
        vertical_dly <= (others => false);
        --hv_toggle <= false;
    elsif rising_edge(clk) then
        vertical_dly <= vertical_enable & vertical_dly(0 to vertical_dly'high-1);
        vertical_enable <= vertical_enable or first_stage_done;
        stream_from_mem <= vertical_enable;
        second_stage_done <= first_stage_done and vertical_rdy;
        read_out_enable <= read_out_enable or second_stage_done;
    
        if row = SYMBOLS-1 and col = SYMBOLS-1 then
            dwt1v_validi <= true;
        else
            dwt1v_validi <= dwt1v_validi;
        end if;
        
        if valid_i = '1' or vertical_enable or first_stage_done then
            
            if col < SYMBOLS-1 then
                col <= col+1;
            else
                col <= to_unsigned(0, col'length);
                if row < SYMBOLS-1 then
                    row <= row+1;
                else
                    row <= to_unsigned(0, row'length);
                end if;
            end if;
        
            s_d_sel <= not s_d_sel;
            
        end if;
            
        if s_d_sel then 
            rd_addr(0) <= s_addr(0);
        else
            rd_addr(0) <= d_addr(0);
        end if;
        rd_addr(1) <= std_logic_vector(col & row);
    end if;
end process sync;

wr_data <= std_logic_vector(signed(d)) when s_d_sel else std_logic_vector(signed(s));

end logic;
