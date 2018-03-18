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
		ACLK            : in  std_logic;
		ARESETN         : in  std_logic;
		S00_AXIS_TREADY : out std_logic;
		S00_AXIS_TDATA  : in  std_logic_vector(C_AXIS_TDATA_WIDTH-1 downto 0);
		--s00_axis_tstrb	: in std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		--s00_axis_tlast	: in std_logic;
		S00_AXIS_TVALID : in  std_logic;
		
		-- Ports of Axi Master Bus Interface M00_AXIS
		--m00_axis_aclk	: in std_logic;
		--m00_axis_aresetn	: in std_logic;
		M00_AXIS_TVALID : out std_logic;
		M00_AXIS_TDATA  : out std_logic_vector(C_AXIS_TDATA_WIDTH-1 downto 0);
		--m00_axis_tstrb	: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		M00_AXIS_TLAST  : out std_logic;
		M00_AXIS_TREADY : in std_logic
	);
	
	--LHB
	signal rst : std_logic;
end axis_dwt2;

architecture arch_imp of axis_dwt2 is begin
	
	-- Add user logic here
	rst <= not ARESETN;
	dwt_2_i : entity work.dwt_2
		generic map (
		    WIDTH => C_AXIS_TDATA_WIDTH,
		    SYMBOLS => C_AXIS_TDATA_FRAMESIZE
		)
		port map (
			clk     => ACLK,
			rst     => ARESETN,
			valid_i => S00_AXIS_TVALID,
			valid_o => M00_AXIS_TVALID,
			rdy_i   => S00_AXIS_TREADY,
			rdy_o   => M00_AXIS_TREADY,
			last_o  => M00_AXIS_TLAST,
			din     => S00_AXIS_TDATA,
			dout    => M00_AXIS_TDATA
		);
	-- User logic ends
	
end arch_imp;
