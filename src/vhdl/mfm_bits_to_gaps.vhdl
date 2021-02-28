
use WORK.ALL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use Std.TextIO.all;
use work.debugtools.all;
  
entity mfm_bits_to_gaps is
  port (
    clock40mhz : in std_logic;

    cycles_per_interval : in unsigned(7 downto 0);
    write_precomp_enable : in std_logic := '0';
    
    -- Are we ready to accept something?
    ready_for_next : out std_logic := '0';
    
    -- Magnetic inversions as output
    f_write : out std_logic := '0';

    -- Input bits fo encoding
    byte_valid : in std_logic := '0';
    byte_in : in unsigned(7 downto 0);

    -- Clock bits
    -- This gets inverted before being XORd with the intended clock bits
    clock_byte_in : in unsigned(7 downto 0) := x"FF"
    
    );
end mfm_bits_to_gaps;

architecture behavioural of mfm_bits_to_gaps is

  signal last_bit0 : std_logic := '0';

  signal clock_bits : unsigned(7 downto 0) := x"FF";

  signal bit_queue : unsigned(15 downto 0);
  signal bits_queued : integer range 0 to 16 := 0;

  signal interval_countdown : integer range 0 to 255 := 0;
  signal transition_point : integer range 0 to 256 := 256;

  signal last_byte_valid : std_logic := '0';
  
begin

  process (clock40mhz) is
    variable state : unsigned(2 downto 0) := "000";
  begin
    if rising_edge(clock40mhz) then

      if interval_countdown = 0 then
        interval_countdown <= to_integer(cycles_per_interval);

        transition_point <= to_integer(cycles_per_interval(7 downto 1));
        
      else
        interval_countdown <= interval_countdown - 1;
      end if;

      -- Request flux reversal
      if interval_countdown = transition_point then
--        report "MFM bit " & std_logic'image(bit_queue(15));
        f_write <= not bit_queue(15);
        bit_queue(15 downto 1) <= bit_queue(14 downto 0);
        if bits_queued /= 0 then
          bits_queued <= bits_queued - 1;
        end if;

        if bits_queued = 16 then
--          report "MFM bit sequence: " & to_string(std_logic_vector(bit_queue));
        end if;
      else
        f_write <= '1';
      end if;

      if bits_queued = 0 then
        ready_for_next <= '1';
      else
        ready_for_next <= '0';
      end if;
      
      
      last_byte_valid <= byte_valid;
      if byte_valid='1' and last_byte_valid='0' then
--        report "latched byte $" & to_hstring(byte_in) & " (clock byte $" & to_hstring(clock_byte_in) & ") for encoding.";
        bits_queued <= 16;
        -- Get the bits to send
        -- Combined data and clock byte to produce the full vector.        
        bit_queue(15) <= last_bit0 xor byte_in(7) xor clock_byte_in(7);
        bit_queue(14) <= byte_in(7);
        bit_queue(13) <= byte_in(7) xor byte_in(6) xor clock_byte_in(6);
        bit_queue(12) <= byte_in(6);
        bit_queue(11) <= byte_in(6) xor byte_in(5) xor clock_byte_in(5);
        bit_queue(10) <= byte_in(5);
        bit_queue( 9) <= byte_in(5) xor byte_in(4) xor clock_byte_in(4);
        bit_queue( 8) <= byte_in(4);
        bit_queue( 7) <= byte_in(4) xor byte_in(3) xor clock_byte_in(3);
        bit_queue( 6) <= byte_in(3);
        bit_queue( 5) <= byte_in(3) xor byte_in(2) xor clock_byte_in(2);
        bit_queue( 4) <= byte_in(2);
        bit_queue( 3) <= byte_in(2) xor byte_in(1) xor clock_byte_in(1);
        bit_queue( 2) <= byte_in(1);
        bit_queue( 1) <= byte_in(1) xor byte_in(0) xor clock_byte_in(0);
        bit_queue( 0) <= byte_in(0);
        last_bit0 <= byte_in(0);
        
        ready_for_next <= '0';
      end if;
      
    end if;    
  end process;
end behavioural;

