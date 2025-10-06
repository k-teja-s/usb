## Interface


| Direction | Size   | Signal Name       | Description                         |
|-----------|--------|-------------------|-----------------------------------|
| Input     | 1      | i_clk_48m         | 48MHz reference clock             |
| Input     | 1      | i_clk_480m        | 480MHz clock from PLL             |
| Input     | 1      | i_rst_n           | Reset, active low                 |
| Input     | 1      | i_pll_locked      | PLL locked indicator              |
| Input     | 1      | i_dp              | USB differential positive input  |
| Input     | 1      | i_dn              | USB differential negative input  |
| Output    | 1      | o_dp              | USB differential positive output |
| Output    | 1      | o_dn              | USB differential negative output |
| Output    | 1      | o_oe              | Output enable                    |
| Output    | 1      | o_pullup_en       | 1.5k pullup control               |
| Input     | 1      | i_connect         | Connection control input          |
| Input     | 1      | i_hs_capable      | High-speed capable input          |
| Input     | 8      | i_utmi_txdata     | UTMI transmit data                |
| Input     | 1      | i_utmi_txvalid    | UTMI transmit data valid          |
| Output    | 1      | o_utmi_txready    | UTMI transmit ready               |
| Output    | 8      | o_utmi_rxdata     | UTMI received data                |
| Output    | 1      | o_utmi_rxvalid    | UTMI received data valid          |
| Output    | 1      | o_utmi_rxerror    | UTMI receive error                |
| Output    | 1      | o_utmi_rxactive   | UTMI receive active               |
| Input     | 2      | i_xcvrselect      | Transceiver select (00=HS, 01=FS, 10=LS, 11=FS4LS) |
| Input     | 2      | i_opmode          | Operation mode (00=Normal, 01=Non-driving, 10=Disable bit stuff) |
| Input     | 1      | i_termselect      | Termination select (0=FS/LS, 1=HS) |
| Input     | 1      | i_suspendm        | Suspend mode (0=Normal, 1=Suspend) |
| Output    | 2      | o_linestate       | Line state (00=SE0, 01=J, 10=K, 11=SE1) |
| Output    | 1      | o_hostdisconnect  | Host disconnect detected          |
| Output    | 1      | o_iddig           | ID digital (0=A-device host, 1=B-device device) |
| Output    | 1      | o_sessend         | Session end                      |
| Output    | 1      | o_sessvld         | Session valid                   |
| Output    | 1      | o_vbusvalid       | VBUS valid                     |
| Output    | 1      | o_hs_mode         | High-speed mode indicator       |
| Output    | 1      | o_fs_mode         | Full-speed mode indicator       |
| Output    | 1      | o_chirp_done      | Chirp done indicator            |
| Output    | 4      | o_phy_state       | PHY state                      |
| Output    | 3      | o_clk_state       | Clock state                    |


### line driver

| Direction | Size | Signal Name     | Description                          |
|-----------|------|------------------|--------------------------------------|
| Input     | 1    | i_clk            | Clock signal                         |
| Input     | 1    | i_rst_n          | Reset signal, active low             |
| Input     | 1    | i_nrzi_data      | NRZI encoded data input              |
| Input     | 1    | i_nrzi_valid     | NRZI data valid indicator            |
| Input     | 1    | i_packet_start   | Indicates start of packet            |
| Input     | 1    | i_packet_end     | Indicates end of packet              |
| Input     | 1    | i_serial_done    | Indicates serial transmission done   |
| Input     | 1    | i_hs_mode        | High-speed mode indicator            |
| Output    | 1    | o_dp             | USB differential positive output     |
| Output    | 1    | o_dn             | USB differential negative output     |
| Output    | 1    | o_oe             | Output enable                        |
| Output    | 1    | o_ready          | Ready signal                         |


### line detector


| Direction | Size  | Signal Name   | Description                           |
|-----------|-------|---------------|-------------------------------------|
| Input     | 1     | i_clk         | Clock signal                        |
| Input     | 1     | i_rst_n       | Reset signal, active low             |
| Input     | 1     | i_dp          | USB differential positive input     |
| Input     | 1     | i_dn          | USB differential negative input     |
| Input     | 1     | i_hs_mode     | High-speed mode indicator            |
| Output    | 2     | o_line_state  | Line state (2-bit)                   |
| Output    | 1     | o_se0         | Single-Ended Zero state indicator    |
| Output    | 1     | o_se1         | Single-Ended One state indicator     |
| Output    | 1     | o_j_state     | J-state indicator                    |
| Output    | 1     | o_k_state     | K-state indicator                    |
| Output    | 1     | o_hs_mode     | High-speed mode output               |
| Output    | 1     | o_squelch     | Squelch indicator                    |

