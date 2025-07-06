//-----------------------------------------------------------------------------
// axi4_basic_random_test.sv - Basic regression test: Randomized bursts
//-----------------------------------------------------------------------------

`ifndef AXI4_BASIC_RANDOM_TEST_SV
`define AXI4_BASIC_RANDOM_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

import axi4_pkg::*;

class axi4_basic_random_test extends axi4_base_test;
    `uvm_component_utils(axi4_basic_random_test)

//----------------------------------------------------------------------------   
//Number of random transactions per run
//----------------------------------------------------------------------------
  localparam int unsigned         NUM_TRANS  = 20;  

//----------------------------------------------------------------------------   
//Constructor
//----------------------------------------------------------------------------
    function new(string name = "axi4_basic_random_test", uvm_component parent);
        super.new(name, parent);
    endfunction

//----------------------------------------------------------------------------   
//Run_phase: loop over several burst lengths and verify write/read-back
//----------------------------------------------------------------------------

    task run_phase(uvm_phase phase);
        
        for (int unsigned i = 0; i < NUM_TRANS; i++) begin
        //Randomize all sequence parameters in test controlled fashion
        if(!seq.randomize() with {
            addr            inside {[32'h0000_0000 : 32'h0000_FFFF]};
            num_beats       inside {[1:16]};
            do_readback     == 1;
        }) begin
            `uvm_warning(get_full_name(), "seq.randomize() failed - using defaults");
        end   

        `uvm_info(get_type_name(), $sformatf("Starting random transaction:%0d beats=%0d addr 0x%0h", 
                i, seq.num_beats, seq.addr), UVM_LOW)

        super.run_phase(phase);
        end
    endtask
endclass

`endif