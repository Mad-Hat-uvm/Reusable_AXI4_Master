//-----------------------------------------------------------------------------
// axi4_base_test.sv — Base UVM Test for AXI4 Master Agent
//-----------------------------------------------------------------------------

`ifndef AXI4_BASE_TEST_SV
`define AXI4_BASE_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

import axi4_pkg::*;

class axi4_base_test extends uvm_test;
    `uvm_component_utils(axi4_base_test)

//----------------------------------------------------------------------------   
//Environment Instantiation + sequence handle
//----------------------------------------------------------------------------
    axi4_env env;
    axi4_base_sequence seq;
//----------------------------------------------------------------------------   
//Constructor
//----------------------------------------------------------------------------
    function new(string name = "axi4_base_test", uvm_component parent);
        super.new(name, parent);
    endfunction

//----------------------------------------------------------------------------   
//Build Phase: instantiate env and bund the DUT interface
//----------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
       
        //1) env setup
        env = axi4_env::type_id::create("env", this);

        //2) create the sequence here
        seq = axi4_base_sequence::type_id::create("seq");
        //tests will override seq.addr, seq.num_beats, etc. before run_phase

        //3) Bind your DUT virtual interface to the agent
        uvm_config_db#(virtual axi4_if.MASTER)::set(null, "env.agent", "vif", dut_if);

        // (Optional) Switch agent into passive only mode
        //uvm_config_db#(bit)::set(this, "env.agent", "is_active", 0);
        
    endfunction

//----------------------------------------------------------------------------   
//Run Phase
//----------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
       

        phase.raise_objection(this);

         //Test controlled randomization of all needed fields

          if (!seq.randomize() with {
            addr inside {[32'h0000_0000 : 32'h0000_FFFF]};   //your address window
            num_beats inside {[1 : 16]};                     //burst length 1 - 16
            do_readback == 1;                                //always verify
          })
          `uvm_warning("RAND_FAIL", "seq.randomize() failed, using defaults");

          //Start and wait
          seq.start(env.agent.sequencer);

          wait(seq.is_done);

        phase.drop_objection(this);
    endtask
endclass

`endif