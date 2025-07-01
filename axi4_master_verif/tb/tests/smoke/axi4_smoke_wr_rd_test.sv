//-----------------------------------------------------------------------------
// axi4_smoke_wr_rd_test.sv - Smoke Test: single beat write + read
//-----------------------------------------------------------------------------

`ifndef AXI4_SMOKE_WR_RD_TEST_SV
`define AXI4_SMOKE_WR_RD_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

import axi4_pkg::*;

class axi4_smoke_wr_rd_test extends axi4_base_test;
    `uvm_component_utils(axi4_smoke_wr_rd_test)

//----------------------------------------------------------------------------   
//Constructor
//----------------------------------------------------------------------------
    function new(string name = "axi4_smoke_wr_rd_test", uvm_component parent);
        super.new(name, parent);
    endfunction

//----------------------------------------------------------------------------   
//Only override run_phase to set parameters; base class handles env setup
//----------------------------------------------------------------------------

    task run_phase(uvm_phase phase);
        
        //set overrides before calling super
        seq.addr        = 32'h1000;
        seq.num_beats   = 1;
        seq.do_readback = 1;

        super.run_phase(phase);
    endtask
endclass

`endif