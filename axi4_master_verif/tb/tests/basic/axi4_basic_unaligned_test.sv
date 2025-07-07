//-----------------------------------------------------------------------------
// axi4_basic_unaligned_test.sv - Basic Regression Test: unaligned addresses & 
//                                partial strobes
//-----------------------------------------------------------------------------

`ifndef AXI4_BASIC_UNALIGNED_TEST_SV
`define AXI4_BASIC_UNALIGNED_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

import axi4_pkg::*;

class axi4_basic_unaligned_test extends axi4_base_test;
    `uvm_component_utils(axi4_basic_unaligned_test)

//----------------------------------------------------------------------------   
//Number of random transactions per run
//----------------------------------------------------------------------------
    localparam int unsigned         NUM_TRANS  = 20; 

//----------------------------------------------------------------------------   
//Constructor
//----------------------------------------------------------------------------
    function new(string name = "axi4_basic_unaligned_test", uvm_component parent);
        super.new(name, parent);
    endfunction

//----------------------------------------------------------------------------   
//Build Phase: Replace the default seq with unaligned sequence
//----------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        seq = axi4_unaligned_sequence::type_id::create("seq");
    endfunction

//----------------------------------------------------------------------------   
//Only override run_phase to set parameters; base class handles env setup
//----------------------------------------------------------------------------

    task run_phase(uvm_phase phase);
       for (int i = 0; i <= NUM_TRANS; i++) begin
        if(!seq.randomize() with {
            addr       inside {[32'h0000_0000 : 32'h0000_FFFF]};
            addr % 4    == 1;
            num_beats   == 1; 
            do_readback == 1;
            custom_strb inside {4'b0011, 4'b0111, 4'b1110}; // partial strobe masks            
        }) begin
            `uvm_warning(get_full_name(), "Randomization failed, using last randomize value");
        end
             `uvm_info(get_type_name(),
        $sformatf("Trial %0d: addr=0x%0h strb=%b", i, seq.addr, seq.custom_strb),
        UVM_MEDIUM
      );
       end
          

        super.run_phase(phase);
    endtask
    
endclass : axi4_basic_unaligned_test

`endif