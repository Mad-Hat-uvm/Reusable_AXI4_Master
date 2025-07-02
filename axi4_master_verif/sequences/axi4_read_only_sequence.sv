//-----------------------------------------------------------------------------
// axi4_read_only_sequence.sv – UVM Sequence for AXI4 Read only Transactions
//-----------------------------------------------------------------------------

`ifndef AXI4_READ_ONLY_SEQUENCE_SV
`define AXI4_READ_ONLY_SEQUENCE_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

import axi4_pkg::*;

class axi4_base_sequence extends uvm_sequence #(axi4_txn);
    `uvm_object_utils(axi4_base_sequence)

    rand bit [ADDR_WIDTH-1 : 0] addr;             //start address
    rand int unsigned           num_beats = 1;    //burst length (1 - 16)

    //Constructor
    function new(string name = "axi4_base_sequence");
        super.new(name);
    endfunction

    virtual task body();

            axi4_txn rd;
            rd = axi4_txn::type_id::create("rd");

            rd.txn_type  = TXN_READ;
            rd.addr      = addr;
            rd.len       = num_beats - 1;   //AXI len = beats - 1
            rd.has_bresp = 0;
            rd.has_rresp = 1;
            start_item(rd);
            finish_item(rd);
           
    endtask
        
    
endclass
`endif