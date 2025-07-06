//-----------------------------------------------------------------------------
// axi4_basic_wr_rd_test.sv - Basic Regression Test: multi-beat write + read-back
//-----------------------------------------------------------------------------

`ifndef AXI4_BASIC_WR_RD_TEST_SV
`define AXI4_BASIC_WR_RD_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

import axi4_pkg::*;

class axi4_basic_wr_rd_test extends axi4_base_test;
    `uvm_component_utils(axi4_basic_wr_rd_test)

//----------------------------------------------------------------------------   
//Optional: Base address and stride can be parameterized via config DB 
//if desired
//----------------------------------------------------------------------------
  localparam bit [ADDR_WIDTH-1:0] BASE_ADDR  = `h0000_0000;
  localparam bit unsigned         ADDR_STEP  = 4;  //bytes between bursts

//----------------------------------------------------------------------------   
//Constructor
//----------------------------------------------------------------------------
    function new(string name = "axi4_basic_wr_rd_test", uvm_component parent);
        super.new(name, parent);
    endfunction

//----------------------------------------------------------------------------   
//Run_phase: loop over several burst lengths and verify write/read-back
//----------------------------------------------------------------------------

    task run_phase(uvm_phase phase);

        //Burst lengths to exercise
        int unsigned lengths[] = '{1, 4, 8, 16};
        
        foreach (lengths[i]) begin
        //Configure the inherited sequence
        seq.addr        = BASE_ADDR + i * ADDR_STEP;
        seq.num_beats   = lengths[i];
        seq.do_readback = 1;

        `uvm_info(get_type_name(), $sformatf("Starting write+read burst %0d beats at addr 0x%0h", 
                seq.num_beats, seq.addr), UVM_MEDIUM)

        super.run_phase(phase);
        end
    endtask
endclass

`endif