library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pipe is
  generic (
    STAGES : natural
    );
  port (
    clk : in std_logic;
    din  : in std_logic_vector;
    dout : out std_logic_vector
    );
end entity;

architecture rtl of pipe is
  subtype word is std_logic_vector(din'length-1 downto 0);
  type word_array is array(natural range <>) of word;
  signal dly : word_array(0 to STAGES-1);
begin

  process(clk) begin
    if rising_edge(clk) then
      dly <= din & dly(0 to dly'high-1);
    end if;
  end process;
  dout <= dly(dly'high);
end architecture;