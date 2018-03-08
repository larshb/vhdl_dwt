library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.utils.all;

entity dwt_2 is
	Generic ( WIDTH   : positive := 16;
			  SYMBOLS : positive := 128 ); -- Assuming square tile
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           valid_i : in STD_LOGIC;
           valid_o : out STD_LOGIC;
           din : in STD_LOGIC_VECTOR (15 downto 0);
           dout : out STD_LOGIC_VECTOR (15 downto 0));
end dwt_2;

architecture logic of dwt_2 is

constant addr_width : positive := log2ceil(SYMBOLS*SYMBOLS);
constant pipe_delay : positive := 4; --Delay of the 1D DWT pipe

-- DWT 1D
subtype pixel_t is SIGNED(WIDTH-1 DOWNTO 0);
signal a, s, d : pixel_t := (others => '0');
signal dwt1_enable : boolean := false;

-- Memory
signal s_d_sel : boolean;
subtype addr_t is std_logic_vector(addr_width-1 downto 0);
signal s_addr, d_addr : addr_t;
type addr_array is array (0 to 1) of addr_t;
signal wr_addr, rd_addr : addr_array;
signal wr_en : boolean := false;
signal wr_data, rd_data : std_logic_vector(WIDTH-1 downto 0);
signal h_mem_wren_sl : std_logic;

signal row, col, col_h : unsigned(addr_width/2-1 downto 0);

-- Control
signal stage1_finish, stage2_finish : boolean; -- row-wise then col-wise horizontal 1D-DWT
signal v_enable, read_out_enable : boolean;
  type v_dly_t is array (0 to pipe_delay-1) of boolean;
signal v_dly : v_dly_t;
signal v_rdy : boolean;
signal v_rdmem : boolean;

begin

a <= signed(rd_data) when v_rdmem else signed(din);
dwt1_enable <= valid_i = '1' or v_enable;

dwt_1 : 	entity work.dwt_1
			generic map (
				WIDTH => WIDTH,
				SYMBOLS => SYMBOLS
			)
			port map (
				clk => clk,
				rst => rst,
				valid_in => dwt1_enable,
				a => a,
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
                WE1 => to_sl(v_rdy),
                WD2 => open,
                RO2 => open,
                WA2 => open,
                RA2 => open,
                WE2 => open
            );
            
col_h <= '0' & col(col'high downto 1); -- unsigned half
s_addr <= std_logic_vector( row &  col_h);
d_addr <= std_logic_vector( row & (col_h+SYMBOLS/2));

valid_1dh : entity work.pipe generic map (STAGES => pipe_delay+1 ) --Extra cycle delay?
            port map ( clk=>clk, din(0)=>valid_i, dout(0)=>h_mem_wren_sl );
            wr_en <= h_mem_wren_sl='1';

addr_pipe : entity work.pipe
            generic map ( STAGES => pipe_delay )
            port map ( clk=>clk, din=>rd_addr(0), dout=>wr_addr(0) );

stage1_finish <= (col = SYMBOLS-1 and row = SYMBOLS-1);
v_rdy <= v_dly(v_dly'high);
valid_o <= to_sl(read_out_enable);
            
sync: process (clk, rst) begin
    if rst = '1' then
        row <= to_unsigned(0, row'length);
        col <= to_unsigned(0, col'length);
        v_enable <= false;
        read_out_enable <= false;
        v_rdmem <= false;
        
        v_dly <= (others => false);
        --hv_toggle <= false;
    elsif rising_edge(clk) then
        v_dly <= v_enable & v_dly(0 to v_dly'high-1);
        v_enable <= v_enable or stage1_finish;
        v_rdmem <= v_enable;
        stage2_finish <= stage1_finish and v_rdy;
        read_out_enable <= read_out_enable or stage2_finish;
        
        if valid_i = '1' or v_enable or stage1_finish then
            
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
            rd_addr(0) <= s_addr;
        else
            rd_addr(0) <= d_addr;
        end if;
        rd_addr(1) <= std_logic_vector(col & row);
    end if;
end process sync;

wr_data <= std_logic_vector(signed(d)) when s_d_sel else std_logic_vector(signed(s));

end logic;
