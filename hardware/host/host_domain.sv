// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 19.03.2017
// Description: Test-harness for Ariane
//              Instantiates an AXI-Bus and memories

`include "register_interface/typedef.svh"
`include "register_interface/assign.svh"
`include "axi/assign.svh"
`include "axi/typedef.svh"

module host_domain 
  import axi_pkg::xbar_cfg_t;
  import ariane_soc::HyperbusNumPhys;
  import ariane_soc::NumChipsPerHyperbus;
  import ariane_soc::*;
  import udma_subsystem_pkg::*;  
  import gpio_pkg::*; 
  import pkg_alsaqr_periph_padframe::*; 
#(
  parameter int unsigned AXI_USER_WIDTH    = 1,
  parameter int unsigned AXI_ADDRESS_WIDTH = 64,
  parameter int unsigned AXI_DATA_WIDTH    = 64,
  // AXILITE parameters
  parameter int unsigned AXI_LITE_AW       = 32,
  parameter int unsigned AXI_LITE_DW       = 32,
`ifdef DROMAJO
  parameter bit          InclSimDTM        = 1'b0,
`else
  parameter bit          InclSimDTM        = 1'b1,
`endif
  parameter int unsigned NUM_WORDS         = 2**25,         // memory size
  parameter bit          StallRandomOutput = 1'b0,
  parameter bit          StallRandomInput  = 1'b0,
  parameter bit          JtagEnable        = 1'b1,
  parameter int unsigned CAM_DATA_WIDTH    = 8,
  parameter int unsigned NUM_GPIO          = 64
) (
  input logic                 rtc_i,
  input logic                 rst_ni,
  input logic                 bypass_clk_i,
  output logic                soc_clk_o,
  output logic                soc_rst_no,
  output logic                clk_cluster_o,
  output logic                rstn_cluster_sync_o,
  output logic                cluster_en_sa_boot_o,
  output logic                cluster_fetch_en_o,
  output logic                dma_pe_evt_ack_o,
  input  logic                dma_pe_evt_valid_i,
  output logic [31:0]         gwt_cfg_o,
  input  logic [31:0]         gwt_cfg_i,
  input  logic                gwt_cfg_ie,
  output logic [127:0]        key_1,
                                        
  REG_BUS.out                 padframecfg_reg_master,
  // CVA6 DEBUG UART
  input logic                 cva6_uart_rx_i,
  output logic                cva6_uart_tx_o, 

  // FROM SimDTM
  input logic                 dmi_req_valid,
  output logic                dmi_req_ready,
  input logic [ 6:0]          dmi_req_bits_addr,
  input logic [ 1:0]          dmi_req_bits_op,
  input logic [31:0]          dmi_req_bits_data,
  output logic                dmi_resp_valid,
  input logic                 dmi_resp_ready,
  output logic [ 1:0]         dmi_resp_bits_resp,
  output logic [31:0]         dmi_resp_bits_data,

  // JTAG
  input logic                 jtag_TCK,
  input logic                 jtag_TMS,
  input logic                 jtag_TDI,
  input logic                 jtag_TRSTn,
  output logic                jtag_TDO_data,
  output logic                jtag_TDO_driven,

  `ifdef XILINX_DDR
  AXI_BUS.Master              axi_ddr_master,
  `endif   
  // SoC to cluster AXI
  AXI_BUS.Master              cluster_axi_master,
  AXI_BUS.Slave               cluster_axi_slave,
  AXI_BUS.Slave               cluster_lite_slave,
  // TLB Config
  AXI_LITE.Master             h2c_tlb_cfg_lite_master,
  AXI_LITE.Master             c2h_tlb_cfg_lite_master,
  // SPIM
  output                      qspi_to_pad_t [N_SPI-1:0] qspi_to_pad,
  input                       pad_to_qspi_t [N_SPI-1:0] pad_to_qspi,
    
  // I2C
  output                      i2c_to_pad_t [N_I2C-1:0] i2c_to_pad,
  input                       pad_to_i2c_t [N_I2C-1:0] pad_to_i2c,
   
  // CAM
  input                       pad_to_cam_t [N_CAM-1:0] pad_to_cam,
    
  // UART
  input                       pad_to_uart_t [N_UART-1:0] pad_to_uart,
  output                      uart_to_pad_t [N_UART-1:0] uart_to_pad,
    
  // SDIO
  output                      sdio_to_pad_t [N_SDIO-1:0] sdio_to_pad,
  input                       pad_to_sdio_t [N_SDIO-1:0] pad_to_sdio,

  //SERIAL LINK
  output                      ser_link_to_pad serial_link_to_pad,
  input                       pad_to_ser_link pad_to_serial_link,

  //CAN
  output                      can_to_pad_t [N_CAN-1 : 0] can_to_pad,
  input                       pad_to_can_t [N_CAN-1 : 0] pad_to_can,
 
  // HYPERBUS
  inout  [HyperbusNumPhys-1:0][NumChipsPerHyperbus-1:0] pad_hyper_csn,
  inout  [HyperbusNumPhys-1:0]                          pad_hyper_ck,
  inout  [HyperbusNumPhys-1:0]                          pad_hyper_ckn,
  inout  [HyperbusNumPhys-1:0]                          pad_hyper_rwds,
  inout  [HyperbusNumPhys-1:0]                          pad_hyper_reset,
  inout  [HyperbusNumPhys-1:0][7:0]                     pad_hyper_dq,

  output                      pwm_to_pad_t pwm_to_pad,

  output gpio_to_pad_t        gpio_to_pad,
  input  pad_to_gpio_t        pad_to_gpio

);

   
   ariane_axi_soc::req_slv_t  axi_cpu_req;
   ariane_axi_soc::resp_slv_t axi_cpu_res;

   ariane_axi_soc::req_slv_mem_t  axi_mem_req;
   ariane_axi_soc::resp_slv_mem_t axi_mem_res;
   
   ariane_axi_soc::req_lite_t  axi_llc_cfg_req;
   ariane_axi_soc::resp_lite_t axi_llc_cfg_res;
   
   // rule definitions
   typedef struct packed {
     int unsigned             idx;
     ariane_axi_soc::addr_t   start_addr;
     ariane_axi_soc::addr_t   end_addr;
   } rule_full_t;
   
   // When changing these parameters, change the L2 size accordingly in ariane_soc_pkg
   localparam NB_L2_BANKS = 8;
   localparam L2_BANK_SIZE = 16384; // 2^14 words (32 bits)

   localparam L2_BANK_ADDR_WIDTH = $clog2(L2_BANK_SIZE);
   localparam L2_MEM_ADDR_WIDTH = $clog2(L2_BANK_SIZE * NB_L2_BANKS) - $clog2(NB_L2_BANKS); 
   localparam L2_DATA_WIDTH = 32 ; // Do not change

   localparam AXI64_2_TCDM32_N_PORTS = 4; // Do not change, to achieve full bandwith from 64 bit AXI and 32 bit tcdm we need 4 ports!
                                          // It is hardcoded in the axi2tcdm_wrap module.

   localparam NB_UDMA_TCDM_CHANNEL = 2;

   logic                                 s_clk_cva6;
   logic                                 s_rstn_cva6_sync;
   logic                                 s_soc_clk;
   logic                                 s_synch_soc_rst;
   logic                                 s_synch_global_rst;
   logic                                 s_rstn_cluster_sync;
   logic                                 s_dm_rst;
   logic                                 ndmreset_n;
   logic [31*4-1:0]                      s_udma_events;
   logic                                 s_dma_pe_evt;
   logic [N_CAN-1:0]                     s_can_irq;

   logic                                 phy_clk;
   logic                                 phy_clk_90;
   logic [127:0]                         s_key_0;
   
   REG_BUS #(
        .ADDR_WIDTH( 32 ),
        .DATA_WIDTH( 32 )
    ) serial_linkcfg_reg_master (
        .clk_i (s_soc_clk)
    ); 


   assign   soc_clk_o  = s_soc_clk;
   assign   soc_rst_no = s_synch_soc_rst;
   assign   rstn_cluster_sync_o = s_rstn_cluster_sync;
   
   AXI_BUS #(
     .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        ),
     .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
     .AXI_ID_WIDTH   ( ariane_soc::IdWidthSlave ),
     .AXI_USER_WIDTH ( AXI_USER_WIDTH           )
   ) l2_axi_bus();
 
   AXI_BUS #(
     .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        ),
     .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
     .AXI_ID_WIDTH   ( ariane_soc::IdWidthSlave ),
     .AXI_USER_WIDTH ( AXI_USER_WIDTH           )
   ) apb_axi_bus();
  
   AXI_BUS #(
     .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        ),
     .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
     .AXI_ID_WIDTH   ( ariane_soc::IdWidthSlave ),
     .AXI_USER_WIDTH ( AXI_USER_WIDTH           )
   ) hyper_axi_bus();

   AXI_BUS #(
     .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        ),
     .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
     .AXI_ID_WIDTH   ( ariane_soc::IdWidthSlave ),
     .AXI_USER_WIDTH ( AXI_USER_WIDTH           )
   ) host_lite_bus ();
   
   AXI_BUS #(
     .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH          ),
     .AXI_DATA_WIDTH ( AXI_DATA_WIDTH             ),
     .AXI_ID_WIDTH   ( ariane_soc::IdWidthSlave+1 ),
     .AXI_USER_WIDTH ( AXI_USER_WIDTH             )
   ) mem_axi_bus ();    

   AXI_LITE #(
    .AXI_ADDR_WIDTH (AXI_LITE_AW),
    .AXI_DATA_WIDTH (AXI_LITE_DW)
   ) llc_cfg_bus();
   
   XBAR_TCDM_BUS axi_bridge_2_interconnect[AXI64_2_TCDM32_N_PORTS]();
   XBAR_TCDM_BUS udma_2_tcdm_channels[NB_UDMA_TCDM_CHANNEL]();
  

  `ifdef XILINX_DDR
   AXI_BUS #(
     .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH           ),
     .AXI_DATA_WIDTH ( AXI_DATA_WIDTH              ),
     .AXI_ID_WIDTH   ( ariane_soc::IdWidthSlave +1 ),
     .AXI_USER_WIDTH ( AXI_USER_WIDTH              )
   ) dummyaxibus();
   assign dummyaxibus.aw_valid  = 1'b0;
   assign dummyaxibus.ar_valid  = 1'b0;
   assign dummyaxibus.w_valid   = 1'b0;
   
   
   `AXI_ASSIGN(axi_ddr_master,mem_axi_bus)
  `endif

  `AXI_ASSIGN_TO_REQ(axi_cpu_req,hyper_axi_bus)
  `AXI_ASSIGN_FROM_RESP(hyper_axi_bus,axi_cpu_res)
  `AXI_ASSIGN_FROM_REQ(mem_axi_bus,axi_mem_req)
  `AXI_ASSIGN_TO_RESP(axi_mem_res,mem_axi_bus)
  `AXI_LITE_ASSIGN_TO_REQ(axi_llc_cfg_req,llc_cfg_bus)
  `AXI_LITE_ASSIGN_FROM_RESP(llc_cfg_bus,axi_llc_cfg_res)
   
   axi_llc_top #(
     .SetAssociativity ( 32'd8                          ),
     .NumLines         ( 32'd256                        ),
     .NumBlocks        ( 32'd8                          ),
     .AxiIdWidth       ( ariane_soc::IdWidthSlave       ),
     .AxiAddrWidth     ( AXI_ADDRESS_WIDTH              ),
     .AxiDataWidth     ( AXI_DATA_WIDTH                 ),
     .AxiUserWidth     ( AXI_USER_WIDTH                 ),
     .AxiLiteAddrWidth ( AXI_LITE_AW                    ),
     .AxiLiteDataWidth ( AXI_LITE_DW                    ),
     .slv_req_t        ( ariane_axi_soc::req_slv_t      ),
     .slv_resp_t       ( ariane_axi_soc::resp_slv_t     ),
     .mst_req_t        ( ariane_axi_soc::req_slv_mem_t  ),
     .mst_resp_t       ( ariane_axi_soc::resp_slv_mem_t ),
     .lite_req_t       ( ariane_axi_soc::req_lite_t     ),
     .lite_resp_t      ( ariane_axi_soc::resp_lite_t    ),
     .rule_full_t      ( rule_full_t                    )
   ) i_axi_llc (
     .clk_i               ( s_soc_clk                                       ),
     .rst_ni              ( s_synch_soc_rst                                 ),
     .test_i              ( 1'b0                                            ),
     .slv_req_i           ( axi_cpu_req                                     ),
     .slv_resp_o          ( axi_cpu_res                                     ),
     .mst_req_o           ( axi_mem_req                                     ),
     .mst_resp_i          ( axi_mem_res                                     ),
     .conf_req_i          ( axi_llc_cfg_req                                 ),
     .conf_resp_o         ( axi_llc_cfg_res                                 ),
     .cached_start_addr_i ( ariane_soc::HYAXIBase                           ),
     .cached_end_addr_i   ( ariane_soc::HYAXIBase + ariane_soc::HYAXILength ),
     .spm_start_addr_i    ( '0                                              ),
     .axi_llc_events_o    (                                                 )
   );
     
   cva6_subsystem # (
        .NUM_WORDS         ( NUM_WORDS  ),
        .InclSimDTM        ( 1'b1       ),
        .StallRandomOutput ( 1'b1       ),
        .StallRandomInput  ( 1'b1       ),
        .JtagEnable        ( JtagEnable )
   ) i_cva6_subsystem (
        .clk_i(s_soc_clk),
        .rst_ni(s_synch_global_rst),
        .cva6_clk_i(s_clk_cva6),
        .cva6_rst_ni(s_rstn_cva6_sync),
        .key_i(s_key_0),
        .rtc_i,
        .dmi_req_valid,
        .dmi_req_ready,
        .dmi_req_bits_addr,
        .dmi_req_bits_op,
        .dmi_req_bits_data,
        .dmi_resp_valid,
        .dmi_resp_ready,
        .dmi_resp_bits_resp,
        .dmi_resp_bits_data,                      
        .jtag_TCK,
        .jtag_TMS,
        .jtag_TDI,
        .jtag_TRSTn,
        .jtag_TDO_data,
        .jtag_TDO_driven,
        .sync_rst_ni          ( s_synch_soc_rst      ),
        .udma_events_i        ( s_udma_events        ),
        .can_irq_i            ( s_can_irq            ),
        .cl_dma_pe_evt_i      ( s_dma_pe_evt         ),
        .dm_rst_o             ( s_dm_rst             ),
        .l2_axi_master        ( l2_axi_bus           ),
        .apb_axi_master       ( apb_axi_bus          ),
        .hyper_axi_master     ( hyper_axi_bus        ),

        .serial_link_to_pad   ( serial_link_to_pad   ),
        .pad_to_serial_link   ( pad_to_serial_link   ),
        .serial_linkcfg_reg_master ( serial_linkcfg_reg_master ),   
        
        .cluster_axi_master   ( cluster_axi_master   ),
        .cluster_axi_slave    ( cluster_axi_slave    ),

        .cva6_uart_rx_i       ( cva6_uart_rx_i       ),
        .cva6_uart_tx_o       ( cva6_uart_tx_o       ),
        .axi_lite_master      ( host_lite_bus        )
    );
   
   
   axi2tcdm_wrap #(
      .AXI_ID_WIDTH   ( ariane_soc::IdWidthSlave ),
      .AXI_USER_WIDTH ( AXI_USER_WIDTH           ),
      .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        )
    ) i_axi2mem_l2 (
      .clk_i       ( s_soc_clk                 ),
      .rst_ni      ( s_synch_soc_rst           ),
      .test_en_i   ( test_en                   ),
      .axi_slave   ( l2_axi_bus                ),
      .tcdm_master ( axi_bridge_2_interconnect ),
      .busy_o      (                           )
    );


   l2_subsystem #(
      .NB_L2_BANKS        ( NB_L2_BANKS              ),
      .L2_BANK_SIZE       ( L2_BANK_SIZE             ), 
      .L2_BANK_ADDR_WIDTH ( L2_BANK_ADDR_WIDTH       ),
      .L2_DATA_WIDTH      ( L2_DATA_WIDTH            )                   
     ) i_l2_subsystem   (
      .clk_i                     ( s_soc_clk                 ),
      .rst_ni                    ( s_synch_soc_rst           ),
      .axi_bridge_2_interconnect ( axi_bridge_2_interconnect ),
      .udma_tcdm_channels        ( udma_2_tcdm_channels      )
     );
   
    edge_propagator_rx ep_dma_pe_evt_i (
        .clk_i   ( s_soc_clk               ),
        .rstn_i  ( s_rstn_cluster_sync     ),
        .valid_o ( s_dma_pe_evt            ),
        .ack_o   ( dma_pe_evt_ack_o        ),
        .valid_i ( dma_pe_evt_valid_i      )
    );
   
   apb_subsystem #(
       .AXI_ADDR_WIDTH ( AXI_ADDRESS_WIDTH        ),
       .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
       .AXI_USER_WIDTH ( AXI_USER_WIDTH           ),
       .NUM_GPIO       ( NUM_GPIO                 )
     ) i_apb_subsystem (
      .clk_i                  ( s_soc_clk                      ),
      .rtc_i                  ( rtc_i                          ),
      .rst_ni                 ( rst_ni                         ),
      .bypass_clk_i           ( bypass_clk_i                   ),  
      .rst_dm_i               ( s_dm_rst                       ),
      .clk_cva6_o             ( s_clk_cva6                     ),
      .clk_soc_o              ( s_soc_clk                      ),
      .rstn_soc_sync_o        ( s_synch_soc_rst                ),
      .rstn_global_sync_o     ( s_synch_global_rst             ),
      .rstn_cva6_sync_o       ( s_rstn_cva6_sync               ),
      .rstn_cluster_sync_o    ( s_rstn_cluster_sync            ),
      .clk_cluster_o          ( clk_cluster_o                  ),
      .cluster_en_sa_boot_o   ( cluster_en_sa_boot_o           ),
      .cluster_fetch_en_o     ( cluster_fetch_en_o             ),
      .key_0                  ( s_key_0                        ),
      .key_1                  ( key_1                          ),
      .gwt_cfg_o              ( gwt_cfg_o                      ),
      .gwt_cfg_i              ( gwt_cfg_i                      ),
      .gwt_cfg_ie             ( gwt_cfg_ie                     ),
                        
      `ifdef XILINX_DDR
      .hyper_axi_bus_slave    ( dummyaxibus                    ),                 
      `else
      .hyper_axi_bus_slave    ( mem_axi_bus                    ),                 
      `endif                        
      .axi_apb_slave          ( apb_axi_bus                    ),
      .udma_tcdm_channels     ( udma_2_tcdm_channels           ),
      .padframecfg_reg_master ( padframecfg_reg_master         ),
      .serial_linkcfg_reg_master ( serial_linkcfg_reg_master   ),

      .events_o               ( s_udma_events                  ),
      .can_irq_o              ( s_can_irq                      ),

      .qspi_to_pad            ( qspi_to_pad                    ),
      .pad_to_qspi            ( pad_to_qspi                    ),
      .i2c_to_pad             ( i2c_to_pad                     ),
      .pad_to_i2c             ( pad_to_i2c                     ),
  	  .pad_to_cam             ( pad_to_cam                     ),
      .pad_to_uart            ( pad_to_uart                    ),
      .uart_to_pad            ( uart_to_pad                    ),
      .sdio_to_pad            ( sdio_to_pad                    ),
      .pad_to_sdio            ( pad_to_sdio                    ),
      .pwm_to_pad             ( pwm_to_pad                     ),
      .can_to_pad             ( can_to_pad                     ),
      .pad_to_can             ( pad_to_can                     ),

      .gpio_to_pad            ( gpio_to_pad                    ),
      .pad_to_gpio            ( pad_to_gpio                    ),

      .pad_hyper_csn,
      .pad_hyper_ck,
      .pad_hyper_ckn,
      .pad_hyper_rwds,
      .pad_hyper_reset,
      .pad_hyper_dq
      );


   axi_lite_subsystem #(
       .AXI_USER_WIDTH      ( AXI_USER_WIDTH    ),
       .AXI_ADDR_WIDTH      ( AXI_ADDRESS_WIDTH ),
       .AXI_DATA_WIDTH      ( AXI_DATA_WIDTH    ),
       .AXI_LITE_ADDR_WIDTH ( AXI_LITE_AW       ),
       .AXI_LITE_DATA_WIDTH ( AXI_LITE_DW       ) 
   ) i_axi_lite_subsystem (
       .clk_i                  ( s_soc_clk               ),
       .rst_ni                 ( rst_ni                  ),
       .host_axi_lite_slave    ( host_lite_bus           ),
       .cluster_axi_lite_slave ( cluster_lite_slave      ),
       .c2h_tlb_cfg_master     ( c2h_tlb_cfg_lite_master ),
       .h2c_tlb_cfg_master     ( h2c_tlb_cfg_lite_master ),
       .llc_cfg_master         ( llc_cfg_bus             )
   );
                      
endmodule
