library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity project_reti_logiche is
    port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_start : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done : out std_logic;
        o_en : out std_logic;
        o_we : out std_logic;
        o_data : out std_logic_vector (7 downto 0)
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
component serializer is
    Port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        ser_load : in std_logic;
        ser_out : out std_logic
    );
end component;
component deserializer is
    Port(
        i_clk : in std_logic;
        i_rst : in std_logic;
        dser_in : in std_logic_vector(1 downto 0);
        dser_out : out std_logic_vector(7 downto 0)
    );
end component;
component memory_manager is
    Port(
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done : out std_logic;
        rmr_sel : in std_logic;
        rmr_load : in std_logic;
        ri_load : in std_logic;
        w01_sel : in std_logic;
        rw_sel : in std_logic
    );
end component;
component cod_conv is
    Port(
        i_clk : in std_logic;
        i_rst : in std_logic;
        cc_dis : in std_logic;
        cc_in : in std_logic;
        cc_out : out std_logic_vector(1 downto 0)
    );
end component;
signal ser_load : std_logic;
signal ser_cc : std_logic;
signal cc_dis : std_logic;
signal cc_rst : std_logic;
signal cc_dser : std_logic_vector(1 downto 0);
signal rmr_sel : std_logic;
signal rmr_load : std_logic;
signal ri_load : std_logic;
signal w01_sel : std_logic;
signal rw_sel : std_logic;
signal done : std_logic;
type state is (IDLE,READ_0,SAVE,READ_I,COMP_00,COMP_01,COMP_02,WRITE_0,COMP_10,COMP_11,COMP_12,WRITE_1,WAIT_S);
signal curr_state, next_state : state;
begin
    Serializer0 : serializer port map(
        i_clk,
        i_rst,
        i_data,
        ser_load,
        ser_cc
    );
    Deserializer0 : deserializer port map(
        i_clk,
        i_rst,
        cc_dser,
        o_data
    );
    MemoryManager0 : memory_manager port map(
        i_clk,
        i_rst,
        i_data,
        o_address,
        done,
        rmr_sel,
        rmr_load,
        ri_load,
        w01_sel,
        rw_sel
    );
    CodConv0 : cod_conv port map(
        i_clk,
        cc_rst,
        cc_dis,
        ser_cc,
        cc_dser
    );
    
    process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            curr_state <= IDLE;
        elsif i_clk'event and i_clk = '1' then
            curr_state <= next_state;
        end if;
    end process;
    
    process(curr_state, i_start, done)
    begin
        next_state <= curr_state;
        case curr_state is
            when IDLE => 
                if i_start = '1' then
                    next_state <= READ_0;
                end if;
            when READ_0 => next_state <= SAVE;
            when SAVE => next_state <= READ_I;
            when READ_I =>
                if done = '0' then
                    next_state <= COMP_00;
                else
                    next_state <= WAIT_S;
                end if;
            when COMP_00 => next_state <= COMP_01;
            when COMP_01 => next_state <= COMP_02;
            when COMP_02 => next_state <= WRITE_0;
            when WRITE_0 => next_state <= COMP_10;
            when COMP_10 => next_state <= COMP_11;
            when COMP_11 => next_state <= COMP_12;
            when COMP_12 => next_state <= WRITE_1;
            when WRITE_1 => next_state <= READ_I;
            when WAIT_S => 
                if i_start = '0' then
                    next_state <= IDLE;
                end if;
        end case;
    end process;
    
    process(curr_state)
    begin
        o_en <= '0';
        o_we <= '0';
        o_done <= '0';
        ser_load <= '0';
        cc_dis <= '0';
        cc_rst <= '0';
        rmr_sel <= '0';
        rmr_load <= '0';
        ri_load <= '0';
        w01_sel <= '0';
        rw_sel <= '0';
        case curr_state is
            when IDLE =>
                rmr_sel <= '1';
                rmr_load <= '1';
                cc_dis <= '1';
                cc_rst <= '1';
            when READ_0 =>
                o_en <= '1';
                rmr_load <= '1';
                cc_dis <= '1';
            when SAVE =>
                ri_load <= '1';
                cc_dis <= '1';
            when READ_I =>
                o_en <= '1';
                cc_dis <= '1';
            when COMP_00 =>
                ser_load <= '1';
            when COMP_01 =>
            when COMP_02 =>
            when WRITE_0 =>
                o_en <= '1';
                o_we <= '1';
                rw_sel <= '1';
            when COMP_10 =>
            when COMP_11 =>
            when COMP_12 =>
            when WRITE_1 =>
                o_en <= '1';
                o_we <= '1';
                w01_sel <= '1';
                rw_sel <= '1';
                rmr_load <= '1';
            when WAIT_S =>
                o_done <= '1';
        end case;
    end process;

end Behavioral;

-- MODULE: SERIALIZER
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity serializer is
    Port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        ser_load : in std_logic;
        ser_out : out std_logic
    );
end serializer;

architecture Behavioral of serializer is
signal rs : std_logic_vector(6 downto 0);
signal mux_rs : std_logic_vector(7 downto 0);
begin
    process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            rs <= "0000000";
        elsif i_clk'event and i_clk = '1' then
            rs <= mux_rs(6 downto 0);
        end if;
    end process;
    
    with ser_load select
        mux_rs <= rs & '0' when '0',
                    i_data when '1',
                    "XXXXXXXX" when others;
                        
    ser_out <= mux_rs(7);

end Behavioral;

-- MODULE: DESERIALIZER
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity deserializer is
    Port(
        i_clk : in std_logic;
        i_rst : in std_logic;
        dser_in : in std_logic_vector(1 downto 0);
        dser_out : out std_logic_vector(7 downto 0)
    );
end deserializer;

architecture Behavioral of deserializer is
signal rd : std_logic_vector(5 downto 0);
begin

process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            rd <= "000000";
        elsif i_clk'event and i_clk = '1' then
            --rd(1 downto 0) <= dser_in;
            rd(0) <= dser_in(0);
            rd(1) <= dser_in(1);
            rd(2) <= rd(0);
            rd(3) <= rd(1);
            rd(4) <= rd(2);
            rd(5) <= rd(3);
        end if;
    end process;

    dser_out <= rd & dser_in;

end Behavioral;

-- MODULE: MEMORY_MANAGER
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity memory_manager is
    Port(
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done : out std_logic;
        rmr_sel : in std_logic;
        rmr_load : in std_logic;
        ri_load : in std_logic;
        w01_sel : in std_logic;
        rw_sel : in std_logic
    );
end memory_manager;

architecture Behavioral of memory_manager is
signal rmr : std_logic_vector(8 downto 0);
signal ri : std_logic_vector(8 downto 0);
signal mux_rmr : std_logic_vector(8 downto 0);
signal mux_w01 : std_logic_vector(15 downto 0);
signal mux_rw : std_logic_vector(15 downto 0);
signal sum_in : std_logic_vector(8 downto 0);
signal sum_rmr : std_logic_vector(8 downto 0);
signal sum_w : std_logic_vector(8 downto 0);
signal sum_w0 : std_logic_vector(15 downto 0);
signal sum_w1 : std_logic_vector(15 downto 0);
begin

    process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            ri <= "000000000";
        elsif i_clk'event and i_clk = '1' then
            if(ri_load = '1') then
                ri <= sum_in;
            end if;
        end if;
    end process;
    process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            rmr <= "000000000";
        elsif i_clk'event and i_clk = '1' then
            if(rmr_load = '1') then
                rmr <= mux_rmr;
            end if;           
        end if;
    end process;

    sum_in <= ('0' & i_data) + "000000001";
    sum_rmr <= rmr + "000000001";
    sum_w <= rmr - "000000001";
    sum_w0 <= ("000000" & sum_w & '0') + "0000001111101000";
    sum_w1 <= sum_w0 + "0000000000000001";
    
    o_done <= '1' when (rmr = ri) else '0';

    with rmr_sel select
        mux_rmr <=  sum_rmr when '0',
                    "000000000" when '1',
                    "XXXXXXXXX" when others;
    with w01_sel select
        mux_w01 <=  sum_w0 when '0',
                    sum_w1 when '1',
                    "XXXXXXXXXXXXXXXX" when others;
    with rw_sel select
        mux_rw <=   "0000000" & rmr when '0',
                    mux_w01 when '1',
                    "XXXXXXXXXXXXXXXX" when others;
    
    o_address <= mux_rw;
    
end Behavioral;

-- MODULE: COD_CONV
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cod_conv is
    Port(
        i_clk : in std_logic;
        i_rst : in std_logic;
        cc_dis : in std_logic;
        cc_in : in std_logic;
        cc_out : out std_logic_vector(1 downto 0)
    );
end cod_conv;

architecture Behavioral of cod_conv is
signal curr_state, next_state : std_logic_vector(1 downto 0);
begin
    
    process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            curr_state <= "00";
        elsif i_clk'event and i_clk = '1' then
            if cc_dis = '0' then
                curr_state <= next_state;
            end if;
        end if;
    end process;
    
    process(curr_state, cc_in)
    begin
        next_state <= curr_state;
        case curr_state is
            when "00" =>
                if cc_in = '1' then
                    next_state <= "10";
                else
                    next_state <= "00";
                end if;
            when "01" =>
                if cc_in = '1' then
                    next_state <= "10";
                else
                    next_state <= "00";
                end if;
            when "10" =>
                if cc_in = '1' then
                    next_state <= "11";
                else
                    next_state <= "01";
                end if;
            when "11" =>
                if cc_in = '1' then
                    next_state <= "11";
                else
                    next_state <= "01";
                end if;
            when others =>
        end case;
    end process;
    
    process(curr_state, cc_in)
    begin
        cc_out <= "00";
        case curr_state is
            when "00" => 
                if cc_in = '1' then
                    cc_out <= "11";
                else
                    cc_out <= "00";
                end if;
            when "01" => 
                if cc_in = '1' then
                    cc_out <= "00";
                else
                    cc_out <= "11";
                end if;
            when "10" => 
                if cc_in = '1' then
                    cc_out <= "10";
                else
                    cc_out <= "01";
                end if;
            when "11" => 
                if cc_in = '1' then
                    cc_out <= "01";
                else
                    cc_out <= "10";
                end if;
            when others =>
        end case;
    end process;

end Behavioral;