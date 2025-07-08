//-----------------------------------------------------------------------------
// axi4_negative_error_test.sv - Stress Burst test: Back to back driving without 
//                             waiting extra cycles
//-----------------------------------------------------------------------------

`ifndef AXI4_NEGATIVE_ERROR_TEST_SV
`define AXI4_NEGATIVE_ERROR_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

import axi4_pkg::*;

class axi4_negative_error_test extends axi4_base_test;
    `uvm_component_utils(axi4_negative_error_test)


//----------------------------------------------------------------------------   
//Constructor
//----------------------------------------------------------------------------
    function new(string name = "axi4_negative_error_test", uvm_component parent);
        super.new(name, parent);
    endfunction

//----------------------------------------------------------------------------   
//Build Phase: Replace the default seq with error_sequence
//----------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        seq = axi4_error_sequence::type_id::create("seq");
    endfunction

//----------------------------------------------------------------------------   
//Run_phase: loop over several burst lengths and verify write/read-back
//----------------------------------------------------------------------------

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        //Scoreboard/monitor should have logged the SLVERR/ DECERR
    endtask
endclass

`endif