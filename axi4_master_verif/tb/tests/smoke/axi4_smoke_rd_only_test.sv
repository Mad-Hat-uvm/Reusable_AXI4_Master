//-----------------------------------------------------------------------------
// axi4_smoke_rd_only_test.sv - Smoke Test: single beat write only
//-----------------------------------------------------------------------------

`ifndef AXI4_SMOKE_RD_ONLY_TEST_SV
`define AXI4_SMOKE_RD_ONLY_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

import axi4_pkg::*;

class axi4_smoke_rd_only_test extends axi4_base_test;
    `uvm_component_utils(axi4_smoke_rd_only_test)

//----------------------------------------------------------------------------   
//Constructor
//----------------------------------------------------------------------------
    function new(string name = "axi4_smoke_rd_only_test", uvm_component parent);
        super.new(name, parent);
    endfunction

//----------------------------------------------------------------------------   
//Build Phase: Replace the default seq with read only variant
//----------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        seq = axi4_read_only_sequence::type_id::create("seq");
    endfunction

//----------------------------------------------------------------------------   
//Only override run_phase to set parameters; base class handles env setup
//----------------------------------------------------------------------------

    task run_phase(uvm_phase phase);

        phase.raise_objection(this);
        
        //set overrides before calling super
        seq.addr        = 32'h1000;
        seq.num_beats   = 1;
        
        
        //Drive the sequence via base logic
        super.run_phase(phase);
        
        phase.drop_objection(this);
    endtask
endclass

`endif