//-----------------------------------------------------------------------------
// axi4_stress_burst_test.sv - Stress Burst test: Back to back driving without 
//                             waiting extra cycles
//-----------------------------------------------------------------------------

`ifndef AXI4_STRESS_BURST_TEST_SV
`define AXI4_STRESS_BURST_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

import axi4_pkg::*;

class axi4_stress_burst_test extends axi4_base_test;
    `uvm_component_utils(axi4_stress_burst_test)

//----------------------------------------------------------------------------   
//Optional: Base address and stride can be parameterized via config DB 
//if desired
//Different values for BURST length as well can be parameterized into an array
//----------------------------------------------------------------------------
  localparam bit [ADDR_WIDTH-1:0] BASE_ADDR  = `h0000_0000;
  localparam bit unsigned         ADDR_STEP  = 4;  //bytes between bursts

  localparam int unsigned         BURSTS[]   = `{32, 64, 128};

//----------------------------------------------------------------------------   
//Constructor
//----------------------------------------------------------------------------
    function new(string name = "axi4_stress_burst_test", uvm_component parent);
        super.new(name, parent);
    endfunction

//----------------------------------------------------------------------------   
//Run_phase: loop over several burst lengths and verify write/read-back
//----------------------------------------------------------------------------

    task run_phase(uvm_phase phase);
        
        foreach (BURSTS[i]) begin
        //Configure the inherited sequence
        seq.addr        = BASE_ADDR + i * ADDR_STEP;
        seq.num_beats   = BURSTS[i];
        seq.do_readback = 1;

        `uvm_info(get_type_name(), $sformatf("Starting write+read burst %0d beats at addr 0x%0h", 
                seq.num_beats, seq.addr), UVM_MEDIUM)

        super.run_phase(phase);
        end
    endtask
endclass

`endif