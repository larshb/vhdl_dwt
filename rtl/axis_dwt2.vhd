library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axis_dwt2 is
	generic (
		-- Users to add parameters here
		
		-- User parameters ends
		-- Do not modify the parameters beyond this line
		
		
		-- Parameters of Axi Slave Bus Interface S00_AXIS
		--C_S00_AXIS_TDATA_WIDTH	: integer	:= 32;
		C_AXIS_TDATA_WIDTH : integer := 16;
		C_AXIS_TDATA_FRAMESIZE : integer := 128 -- WARNING: Not standard
		
		-- Parameters of Axi Master Bus Interface M00_AXIS
		--C_M00_AXIS_TDATA_WIDTH	: integer	:= 32
		--C_M00_AXIS_START_COUNT	: integer	:= 32
	);
	port (
		-- Users to add ports here
		
		-- User ports ends
		-- Do not modify the ports beyond this line
		
		
		-- Ports of Axi Slave Bus Interface S00_AXIS
		aclk            : in  std_logic;
		aresetn         : in  std_logic;
		s00_axis_tready : out std_logic;
		s00_axis_tdata  : in  std_logic_vector(C_AXIS_TDATA_WIDTH-1 downto 0);
		--s00_axis_tstrb	: in std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		--s00_axis_tlast	: in std_logic;
		s00_axis_tvalid : in  std_logic;
		
		-- Ports of Axi Master Bus Interface M00_AXIS
		--m00_axis_aclk	: in std_logic;
		--m00_axis_aresetn	: in std_logic;
		m00_axis_tvalid : out std_logic;
		m00_axis_tdata  : out std_logic_vector(C_AXIS_TDATA_WIDTH-1 downto 0);
		--m00_axis_tstrb	: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		m00_axis_tlast  : out std_logic;
		m00_axis_tready : in std_logic
	);
	
	--LHB
	signal rst : std_logic;
end axis_dwt2;

architecture arch_imp of axis_dwt2 is begin
	
	-- Add user logic here
	rst <= not aresetn;
	dwt_2_i : entity work.dwt_2
		generic map (
		    WIDTH => C_AXIS_TDATA_WIDTH,
		    SYMBOLS => C_AXIS_TDATA_FRAMESIZE
		)
		port map (
			clk     => aclk,
			rst     => aresetn,
			valid_i => s00_axis_tvalid,
			valid_o => m00_axis_tvalid,
			rdy_i   => s00_axis_tready,
			rdy_o   => m00_axis_tready,
			last_o  => m00_axis_tlast,
			din     => s00_axis_tdata,
			dout    => m00_axis_tdata
		);
	-- User logic ends
	
end arch_imp;
