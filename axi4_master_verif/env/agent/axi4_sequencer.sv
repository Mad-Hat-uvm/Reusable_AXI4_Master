//-------------------------------------------------------------
// AXI4 Sequencer
// - Cordinates transaction flow between sequence and driver
//-------------------------------------------------------------
`ifndef AXI4_SEQUENCER_SV
`define AXI4_SEQUENCER_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class axi4_sequencer extends uvm_sequencer #(axi4_txn);
 `uvm_component_utils(axi_sequencer)

  //Constructor
 function new(string name, uvm_component parent);
  super.new(name, parent);
 endfunction

endclass