//-----------------------------------------------------------------------------
// axi4_smoke_wr_only_test.sv - Smoke Test: single beat write only
//-----------------------------------------------------------------------------

`ifndef AXI4_SMOKE_WR_ONLY_TEST_SV
`define AXI4_SMOKE_WR_ONLY_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

import axi4_pkg::*;

class axi4_smoke_wr_only_test extends axi4_base_test;
    `uvm_component_utils(axi4_smoke_wr_only_test)

//----------------------------------------------------------------------------   
//Constructor
//----------------------------------------------------------------------------
    function new(string name = "axi4_smoke_wr_only_test", uvm_component parent);
        super.new(name, parent);
    endfunction

//----------------------------------------------------------------------------   
//Only override run_phase to set parameters; base class handles env setup
//----------------------------------------------------------------------------

    task run_phase(uvm_phase phase);
        
        //set overrides before calling super
        seq.addr        = 32'h2000;
        seq.num_beats   = 1;
        seq.do_readback = 0;

        super.run_phase(phase);
    endtask
endclass

`endif