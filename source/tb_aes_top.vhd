-- File name:   tb_key_scheduler.vhd
-- Created:     2009-04-06
-- Author:      Zachary Curosh
-- Lab Section: 337-02
-- Version:     2.0 Revamped Test Bench with external test vectors!


use work.aes.all;
use work.aes_textio.all;
use work.numeric_std_textio.all;

use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity tb_aes_top is
   
   generic (
      clk_per  : time := 10 ns
   );
   
end entity tb_aes_top;


architecture test of tb_aes_top is
   
   
   signal clk     : std_logic := '0';
   signal nrst    : std_logic := '1';
   signal rx_data : byte;
   signal tx_data : byte;
   signal send_ct : std_logic := '0';
   signal got_key : std_logic := '0';
   signal got_pt  : std_logic := '0';
   signal aes_done   : std_logic;
   -- clock only runs when stop isnt asserted
   signal stop    : std_logic := '1';
   
   
begin
   
   
   dut : entity work.aes_top(structural) port map (
      clk => clk, nrst => nrst, rx_data => rx_data,
      got_key => got_key, got_pt => got_pt,
      aes_done => aes_done, tx_data => tx_data,
      send_ct => send_ct
   );
   
   
   clk <= not clk and not stop after clk_per/2;
   
   
process
   
   
   file data : text open read_mode is "test_vectors/tb_aes_top.dat";
   file data2 : text;
   variable sample, buf    : line;
   variable gold_enc_key   : key_type;
   variable gold_pt        : state_type;
   variable gold_ct        : state_type;
   variable f_status       : FILE_OPEN_STATUS;
   
   
begin   
   stop <= '0';
   
   nrst <= '0';
   wait for clk_per;
   nrst <= '1';
   wait for clk_per;
      
   -- leda DCVHDL_165 off
   file_open(f_status, data2, "test_vectors/tb_aes_top_test.dat", write_mode);
   while not endfile(data) loop
      readline(data, sample);
      hread(sample, gold_enc_key);
      hread(sample, gold_pt);
      hread(sample, gold_ct);
      got_key <= '1';

      -- file write test, only writes the last line of the input file, not all the lines
      
      hwrite(buf, gold_enc_key);
      write(buf, ' ');
      hwrite(buf, gold_pt);
      write(buf, ' ');
      hwrite(buf, gold_ct);
      writeline(data2, buf);

      -- end file write test
      
      wait for clk_per;
      for i in g_index loop
         got_key <= '1';
         rx_data <= gold_enc_key(i mod 4, i / 4);
         wait for clk_per;
         got_key <= '0';
      end loop;
      wait for clk_per*2;
      got_pt <= '1';
      wait for clk_per;
      for i in g_index loop
         got_pt <= '1';
         rx_data <= gold_pt(i mod 4, i / 4);
         wait for clk_per;
         got_pt <= '0';
      end loop;
      wait until aes_done = '1';
      wait for clk_per;
      wait for clk_per/2;
      send_ct <= '1';
      wait for clk_per;
      send_ct <= '0';
      for i in g_index loop
         assert tx_data = gold_ct(i mod 4, i / 4);
         wait for clk_per;
      end loop;
      wait for clk_per*10;
   end loop;
   file_close(data2);
   -- leda DCVHDL_165 on
   
   stop <= '1';
   
   wait;
   
end process;

end architecture test;

