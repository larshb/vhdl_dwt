library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity mem is
    Generic ( data_width : natural := 16;
              addr_width : natural := 14 -- ceil(log2(128*128)
    );
    
    Port ( clk : in STD_LOGIC;
    
           WD1 :  in std_logic_vector(data_width-1 downto 0) := (others => '0'); -- Data
           RO1 : out std_logic_vector(data_width-1 downto 0) := (others => '0'); -- Data
           WA1 :  in std_logic_vector(addr_width-1 downto 0) := (others => '0'); -- Write address
           RA1 :  in std_logic_vector(addr_width-1 downto 0) := (others => '0'); -- Read address
           WE1 :  in std_logic := '0'; -- Write enable

           WD2 :  in std_logic_vector(data_width-1 downto 0) := (others => '0'); -- Data
           RO2 : out std_logic_vector(data_width-1 downto 0) := (others => '0'); -- Data
           WA2 :  in std_logic_vector(addr_width-1 downto 0) := (others => '0'); -- Write address
           RA2 :  in std_logic_vector(addr_width-1 downto 0) := (others => '0'); -- Read address
           WE2 :  in std_logic := '0' -- Write enable
    );
           
end mem;

architecture logic of mem is

	subtype TmemWord is std_logic_vector(data_width-1 downto 0);
    type    Tmem     is array(0 to 2**addr_width-1) of TmemWord;    
    shared variable memory: Tmem:= (others => (others => '0'));

begin

    process(clk) is
    begin
        if (rising_edge(clk)) then         
            if (WE1 = '1') then
                memory(conv_integer(WA1)) := WD1;
            end if;
        end if;
    end process;
  
  
    process(clk) is
    begin
        if (rising_edge(clk)) then
            if (WE2 = '1') then
                memory(conv_integer(WA2)) := WD2;
            end if;
        end if;
    end process;
    
    RO1 <= memory(conv_integer(RA1));
    RO2 <= memory(conv_integer(RA2));
    
end logic;
