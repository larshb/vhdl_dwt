library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.utils.all;

entity dwt_2 is
    Generic ( 
        WIDTH   : positive := 16;
        SYMBOLS : positive := 128 );
    Port ( 
        clk     : in  STD_LOGIC;
        rst     : in  STD_LOGIC;
        valid_i : in  STD_LOGIC;
        valid_o : out STD_LOGIC;
        rdy_i   : out STD_LOGIC;
        rdy_o   : in  STD_LOGIC; -- TODO :  Fix handshake
        last_o  : out STD_LOGIC;
        din     : in  STD_LOGIC_VECTOR (WIDTH-1 downto 0);
        dout    : out STD_LOGIC_VECTOR (WIDTH-1 downto 0));
end dwt_2;

architecture logic of dwt_2 is
    
    constant addr_width : positive := log2ceil(SYMBOLS*SYMBOLS);
    constant pipe_delay : positive := 4; --Delay of the 1D DWT pipe
    subtype component_t is SIGNED(WIDTH-1 downto 0);
    
    -- DWT 1D
    signal x_in, a_out, d_out : component_t := (others => '0');
    signal dwt1_enable        : boolean     := false;
    
    -- Memory
    signal a_sel : boolean;
    
    subtype addr_t is std_logic_vector(addr_width-1 downto 0);
    signal sel_addr, wr_addr, rd_addr : addr_t;
    
    signal wr_en_v          : boolean := false;
    signal wr_en_h_sl       : std_logic; --Write enable horizontal (standard logic)
    signal wr_data, rd_data : std_logic_vector(WIDTH-1 downto 0);
    
    signal row, col : unsigned(addr_width/2-1 downto 0);
    
    -- Control
    signal stage_last, stage_last_d : boolean; --horizontal, then vertical, 1D-DWT
    signal v_enable, v_stage, read_out_enable : boolean;
    
    type v_dly_t is array (0 to pipe_delay-1) of boolean;
    signal v_dly : v_dly_t;
    
    signal valid_o_bool, last_o_bool, rdy_i_reg : boolean;
    
    signal halt : boolean;
    
begin
    
    x_in        <= signed(rd_data) when v_stage else signed(din);
    dwt1_enable <= valid_i = '1' or v_enable; --horizontal on input, vertical from mem
    
    dwt_1 : entity work.dwt_1
        generic map (
            WIDTH   => WIDTH,
            SYMBOLS => SYMBOLS
        )
        port map (
            clk      => clk,
            rst      => rst,
            valid_in => dwt1_enable,
            --valid_out => wr_en_h,
            x_in     => x_in ,
            a_out    => a_out,
            d_out    => d_out
        );
    
    mem_h : entity work.mem
        generic map(
            data_width => WIDTH,
            addr_width => addr_width
        )
        port map (
            clk => clk,
            WD1 => wr_data,
            RO1 => rd_data,
            WA1 => wr_addr,
            RA1 => rd_addr,
            WE1 => wr_en_h_sl,
            WD2 => open,
            RO2 => open,
            WA2 => open,
            RA2 => open,
            WE2 => open
        );
    
    mem_v : entity work.mem
        generic map(
            data_width => WIDTH,
            addr_width => addr_width
        )
        port map (
            clk => clk,
            WD1 => wr_data,
            RO1 => dout,
            WA1 => wr_addr,
            RA1 => rd_addr,
            WE1 => to_sl(wr_en_v),
            WD2 => open,
            RO2 => open,
            WA2 => open,
            RA2 => open,
            WE2 => open
        );
    
        valid_1dh : entity work.pipe generic map (STAGES => pipe_delay+1 ) --Extra cycle delay?
        port map ( clk                                   => clk, din(0) => valid_i, dout(0) => wr_en_h_sl );
    
    addr_pipe : entity work.pipe
        generic map ( STAGES => pipe_delay )
        port map ( clk       => clk, din => sel_addr, dout => wr_addr );
    
    stage_last   <= (col = SYMBOLS-1 and row = SYMBOLS-1);
    wr_en_v      <= v_dly(v_dly'high);
    valid_o_bool <= read_out_enable;
    wr_data      <= std_logic_vector(signed(d_out)) when a_sel else std_logic_vector(signed(a_out));
    
    sync : process (clk, rst)
    sync : process (clk, rst, halt)
        variable col_h : unsigned(addr_width/2-1 downto 0);
    begin
        if rst = '1' then
        if rst = '1' or halt then --TOOD  :   Sync halt
            rdy_i_reg       <= true;
            row             <= to_unsigned(0, row'length);
            col             <= to_unsigned(0, col'length);
            v_enable        <= false;
            read_out_enable <= false;
            v_stage         <= false;
            a_sel           <= false;
            v_dly           <= (others => false);
            halt            <= false;
        elsif rising_edge(clk) then
            
            -- Registers
            v_dly           <= v_enable & v_dly(0 to v_dly'high-1);
            v_enable        <= v_enable or stage_last;
            v_stage         <= v_enable;
            stage_last_d    <= stage_last and wr_en_v;
            read_out_enable <= read_out_enable or stage_last_d;
            rd_addr         <= std_logic_vector(col & row);
            halt            <= halt or last_o_bool;
            rdy_i_reg       <= (not stage_last_reg) and rdy_i_reg;
            
            -- Memory control
            if valid_i = '1' or v_enable or stage_last then
                a_sel <= not a_sel;
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
            end if;
            
            -- Deinterleave
            col_h := '0' & col(col'high downto 1); --unsigned half
            if a_sel then 
                sel_addr <= std_logic_vector( row & col_h); --approx
            else
                sel_addr <= std_logic_vector( row & (col_h+SYMBOLS/2)); --detail
            end if;
            
        end if;
    end process sync;
    
    -- Output
    valid_o <= '1' when valid_o_bool else '0';
    last_o  <= '1' when stage_last_d and valid_o_bool else '0';
    rdy_i <= '1' when rdy_i_reg else '0';
    
end logic;
