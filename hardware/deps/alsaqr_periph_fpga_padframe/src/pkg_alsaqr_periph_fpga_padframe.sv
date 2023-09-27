// File auto-generated by Padrick 0.1.0.post0.dev49+g9979c54.dirty
package pkg_alsaqr_periph_fpga_padframe;

  //Structs for periphs

  // Port Group signals
   typedef struct packed {
      logic        clk_i;
      logic        csn0_i;
      logic        sd0_i;
     } pad_domain_periphs_port_group_spi0_soc2pad_t;

   typedef struct packed {
      logic        sd1_o;
     } pad_domain_periphs_port_group_spi0_pad2soc_t;

   typedef struct packed {
      logic        scl_i;
      logic        scl_oe_i;
      logic        sda_i;
      logic        sda_oe_i;
     } pad_domain_periphs_port_group_i2c0_soc2pad_t;

   typedef struct packed {
      logic        scl_o;
      logic        sda_o;
     } pad_domain_periphs_port_group_i2c0_pad2soc_t;

   typedef struct packed {
      logic        tx_i;
     } pad_domain_periphs_port_group_uart0_soc2pad_t;

   typedef struct packed {
      logic        rx_o;
     } pad_domain_periphs_port_group_uart0_pad2soc_t;

   typedef struct packed {
      logic        clk_i;
      logic        cmd_i;
      logic        cmd_oen_i;
      logic        data0_i;
      logic        data0_oen_i;
      logic        data1_i;
      logic        data1_oen_i;
      logic        data2_i;
      logic        data2_oen_i;
      logic        data3_i;
      logic        data3_oen_i;
     } pad_domain_periphs_port_group_sdio0_soc2pad_t;

   typedef struct packed {
      logic        cmd_o;
      logic        data0_o;
      logic        data1_o;
      logic        data2_o;
      logic        data3_o;
     } pad_domain_periphs_port_group_sdio0_pad2soc_t;

   typedef struct packed {
      logic        gpio0_d_i;
      logic        gpio0_i;
      logic        gpio1_d_i;
      logic        gpio1_i;
      logic        gpio2_d_i;
      logic        gpio2_i;
      logic        gpio3_d_i;
      logic        gpio3_i;
      logic        gpio4_d_i;
      logic        gpio4_i;
      logic        gpio5_d_i;
      logic        gpio5_i;
      logic        gpio6_d_i;
      logic        gpio6_i;
      logic        gpio7_d_i;
      logic        gpio7_i;
      logic        gpio8_d_i;
      logic        gpio8_i;
      logic        gpio9_d_i;
      logic        gpio9_i;
      logic        gpio10_d_i;
      logic        gpio10_i;
      logic        gpio11_d_i;
      logic        gpio11_i;
      logic        gpio12_d_i;
      logic        gpio12_i;
      logic        gpio13_d_i;
      logic        gpio13_i;
     } pad_domain_periphs_port_group_gpio_b_soc2pad_t;

   typedef struct packed {
      logic        gpio0_o;
      logic        gpio1_o;
      logic        gpio2_o;
      logic        gpio3_o;
      logic        gpio4_o;
      logic        gpio5_o;
      logic        gpio6_o;
      logic        gpio7_o;
      logic        gpio8_o;
      logic        gpio9_o;
      logic        gpio10_o;
      logic        gpio11_o;
      logic        gpio12_o;
      logic        gpio13_o;
     } pad_domain_periphs_port_group_gpio_b_pad2soc_t;

   typedef struct packed {
     pad_domain_periphs_port_group_spi0_soc2pad_t spi0;
     pad_domain_periphs_port_group_i2c0_soc2pad_t i2c0;
     pad_domain_periphs_port_group_uart0_soc2pad_t uart0;
     pad_domain_periphs_port_group_sdio0_soc2pad_t sdio0;
     pad_domain_periphs_port_group_gpio_b_soc2pad_t gpio_b;
     } pad_domain_periphs_ports_soc2pad_t;

   typedef struct packed {
     pad_domain_periphs_port_group_spi0_pad2soc_t spi0;
     pad_domain_periphs_port_group_i2c0_pad2soc_t i2c0;
     pad_domain_periphs_port_group_uart0_pad2soc_t uart0;
     pad_domain_periphs_port_group_sdio0_pad2soc_t sdio0;
     pad_domain_periphs_port_group_gpio_b_pad2soc_t gpio_b;
     } pad_domain_periphs_ports_pad2soc_t;


  //Toplevel structs

  typedef struct packed {
    pad_domain_periphs_ports_pad2soc_t periphs;
  } port_signals_pad2soc_t;

  typedef struct packed {
    pad_domain_periphs_ports_soc2pad_t periphs;
  } port_signals_soc2pad_t;


endpackage : pkg_alsaqr_periph_fpga_padframe