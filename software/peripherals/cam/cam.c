/*
 * Copyright (C) 2018 ETH Zurich and University of Bologna
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* 
 * Mantainer: Luca Valente (luca.valente2@unibo.it)
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include "utils.h"
#include "udma.h"
#include "udma_cpi_v1.h"
#include "rgb565_f0.h"

//This test receives 32*32*2 bytes from the VIP, change the VIP to receive bigger data
#define HRES 32
#define VRES 32

#define BUFFER_SIZE 10
#define BUFFER_SIZE_READ 12
#define N_CAM 2

#define GPIO_PADDIR_0_31_OFFSET 0x0
#define GPIO_PADEN_0_31_OFFSET 0x4
#define GPIO_PADOUT_0_31_OFFSET 0xC
#define GPIO_GPIOEN_32_63_OFFSET 0x3C
#define GPIO_PADIN_32_63_OFFSET 0x40

#define PRINTF_ON

int main(){
  int error=0;

  //config registers
  uint32_t reg=0;
  uint16_t concat=0;
  uint32_t address;
  uint32_t val_wr = 0x00000000;

  uint16_t *rx_addr= (uint16_t*) 0x1C001000;

   #ifdef FPGA_EMULATION
  int baud_rate = 115200;
  int test_freq = 50000000;
  #else
  set_flls();
  int baud_rate = 115200;
  int test_freq = 100000000;
  #endif  
  uart_set_cfg(0,(test_freq/baud_rate)>>4);

  #ifdef FPGA_EMULATION
    return 0;
  #else
    #ifdef SIMPLE_PAD
      return 0;
    #else
      //Config pad_gpio_b_11 as GPIO
      alsaqr_periph_padframe_periphs_b_11_mux_set( 1 );
      //Config padframe on CAM0
      alsaqr_periph_padframe_periphs_a_42_mux_set( 1 );
      alsaqr_periph_padframe_periphs_a_43_mux_set( 1 );
      alsaqr_periph_padframe_periphs_b_19_mux_set( 1 );
      alsaqr_periph_padframe_periphs_a_44_mux_set( 1 );
      alsaqr_periph_padframe_periphs_a_45_mux_set( 1 );
      alsaqr_periph_padframe_periphs_a_46_mux_set( 1 );
      alsaqr_periph_padframe_periphs_a_47_mux_set( 1 );
      alsaqr_periph_padframe_periphs_b_20_mux_set( 1 );
      alsaqr_periph_padframe_periphs_a_48_mux_set( 1 );
      alsaqr_periph_padframe_periphs_a_49_mux_set( 1 );
      alsaqr_periph_padframe_periphs_a_50_mux_set( 1 );

      //Config pad_gpio_b_12 as GPIO
      alsaqr_periph_padframe_periphs_b_12_mux_set( 1 );
      //Config padframe on CAM1
      alsaqr_periph_padframe_periphs_a_51_mux_set( 1 );
      alsaqr_periph_padframe_periphs_b_21_mux_set( 1 );
      alsaqr_periph_padframe_periphs_a_52_mux_set( 1 );
      alsaqr_periph_padframe_periphs_a_53_mux_set( 1 );
      alsaqr_periph_padframe_periphs_a_54_mux_set( 1 );
      alsaqr_periph_padframe_periphs_b_22_mux_set( 1 );
      alsaqr_periph_padframe_periphs_b_23_mux_set( 1 );
      alsaqr_periph_padframe_periphs_b_24_mux_set( 1 );
      alsaqr_periph_padframe_periphs_a_55_mux_set( 1 );
      alsaqr_periph_padframe_periphs_a_56_mux_set( 1 );
      alsaqr_periph_padframe_periphs_a_57_mux_set( 1 );
    #endif    
  #endif

  for(int u = 0; u < N_CAM; u++){

    int j = 0;

    //Enable GPIO
    address = ARCHI_GPIO_ADDR + GPIO_PADEN_0_31_OFFSET;
    switch(u){
      case 0:
        val_wr = 1 << 11; //Enable GPIO 11
        break;
      case 1:
        val_wr = 1 << 12; //Enable GPIO 12
        break;
    }
    pulp_write32(address, val_wr);
    while(pulp_read32(address) != val_wr);
    
    //Set GPIO direction
    address = ARCHI_GPIO_ADDR + GPIO_PADDIR_0_31_OFFSET;
    switch(u){
      case 0:
        val_wr = 1 << 11; //Set GPIO 11 direction as OUT
        break;
      case 1:
        val_wr = 1 << 12; //Set GPIO 12 direction as OUT
        break;
    }
    pulp_write32(address, val_wr);
    while(pulp_read32(address) != val_wr);

    //Disable the Camera VIP by GPIO 0 -> 0, GPIO 1 -> 0
    address = ARCHI_GPIO_ADDR + GPIO_PADOUT_0_31_OFFSET;
    val_wr = 0x0;
    pulp_write32(address, val_wr);
    while(pulp_read32(address) != val_wr);
    
    #ifdef PRINTF_ON
      printf("Camera Vip Disabled\n");
      uart_wait_tx_done();
    #endif

    //clear rx buffer
    for(int i=0; i< HRES * VRES; i++){
      rx_addr[i]=0x00;
    }

    uint32_t udma_cam_channel_base = hal_udma_channel_base(UDMA_CHANNEL_ID(ARCHI_UDMA_CAM_ID(u))); //select the camera ID=u
    barrier();

    #ifdef PRINTF_ON
      printf("Channel base: %x\n", udma_cam_channel_base);
      uart_wait_tx_done();
    #endif

    plp_udma_cg_set(plp_udma_cg_get() | (0xffffffff));
    #ifdef PRINTF_ON
      printf("Enable all CG\n");
      uart_wait_tx_done();
    #endif
    barrier();

    //write RX_SADDR register: it sets the L2 start address 
    udma_cpi_cam_rx_saddr_set(udma_cam_channel_base, 0x1C001000);
    barrier();
      
    //write RX_SIZE register: it sets the buffer syze in bytes
    udma_cpi_cam_rx_size_set(udma_cam_channel_base, N_PIXEL);

    reg|= 1<<UDMA_CPI_CAM_CFG_FILTER_R_COEFF_BIT | 1<<UDMA_CPI_CAM_CFG_FILTER_G_COEFF_BIT | 1<<UDMA_CPI_CAM_CFG_FILTER_B_COEFF_BIT ;
    udma_cpi_cam_cfg_filter_set(udma_cam_channel_base, reg);
    barrier();

    reg=0;
    reg|= 1<<UDMA_CPI_CAM_VSYNC_POLARITY_VSYNC_POLARITY_BIT;
    udma_cpi_cam_vsync_polarity_set(udma_cam_channel_base, reg);

    reg=0;
    reg|= 1<<UDMA_CPI_CAM_CFG_GLOB_EN_BIT | 4<< UDMA_CPI_CAM_CFG_GLOB_FORMAT_BIT;
    udma_cpi_cam_cfg_glob_set(udma_cam_channel_base, reg);
    barrier();

    reg=0;
    reg|= 1<<UDMA_CPI_CAM_RX_CFG_EN_BIT | 1<<UDMA_CPI_CAM_RX_CFG_DATASIZE_BIT | 0<<UDMA_CPI_CAM_RX_CFG_CONTINOUS_BIT;
    udma_cpi_cam_rx_cfg_set(udma_cam_channel_base,reg);
    barrier();

    #ifdef PRINTF_ON
      printf("End Of Config\n");
      uart_wait_tx_done();
    #endif

    //Enable Camera VIP
    address = ARCHI_GPIO_ADDR + GPIO_PADOUT_0_31_OFFSET;
    switch(u){
      case 0:
        val_wr = 1 << 11; //Enable Camera VIP by GPIO 0 -> 1
        break;
      case 1:
        val_wr = 1 << 12; //Enable Camera VIP by GPIO 1 -> 1
        break;
    }
    pulp_write32(address, val_wr);
    while(pulp_read32(address) != val_wr);

    #ifdef PRINTF_ON
      printf("Camera Vip Enabled\n");
      uart_wait_tx_done();
    #endif
    
    //wait_cycles(70000);
    do{
      #ifdef PRINTF_ON
        printf("Still writing...\n");
        uart_wait_tx_done();
      #endif
    }while(udma_cpi_cam_rx_size_get(udma_cam_channel_base)!=0);

    #ifdef PRINTF_ON
      printf("End Transaction\n");
      uart_wait_tx_done();
    #endif

    for (int i=0; i<N_PIXEL; i+=2){
      concat= frame_0[i]<<8 | frame_0[i+1];
      if(rx_addr[j]!=concat){
        error++;
        printf("Error CAM_%0d: L2[%d] = %x - Pixel[%d] = %x\n", u, j, rx_addr[j], j, concat);
      }
      j++;
    }

    //Disable GPIO
    address = ARCHI_GPIO_ADDR + GPIO_PADEN_0_31_OFFSET;
    switch(u){
      case 0:
        val_wr = 0 << 11; //Disable GPIO 11
        break;
      case 1:
        val_wr = 0 << 12; //Disable GPIO 12
        break;
    }
    pulp_write32(address, val_wr);
    while(pulp_read32(address) != val_wr);
  }

  if(error!=0)
    printf("Test FAILED with :%d\n",error);
  else
    printf("Test PASSED\n");

  uart_wait_tx_done();

  return error;
}
