//-----------------------------------------------------------------------------
// axi4_base_sequence.sv – Base UVM Sequence for AXI4 Transactions
//-----------------------------------------------------------------------------

`ifndef AXI4_BASE_SEQUENCE_SV
`define AXI4_BASE_SEQUENCE_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

import axi4_pkg::*;

class axi4_base_sequence extends uvm_sequence #(axi4_txn);
    `uvm_object_utils(axi4_base_sequence)

    rand bit [ADDR_WIDTH-1 : 0] addr;             //start address
    rand int unsigned           num_beats = 1;    //burst length (1 - 16)
    rand bit [31:0]             data_stride = 4;  //increment between data values
    bit                         do_readback = 0;  //issue read after write

    //Constructor
    function new(string name = "axi4_base_sequence");
        super.new(name);
    endfunction

    task body();
        axi4_txn tr;

        //1)Build and start a write transaction
            tr = axi4_txn::type_id::create("tr");

            tr.txn_type  = TXN_WRITE;
            tr.addr      = addr;
            tr.len       = num_beats - 1;   //AXI len = beats - 1
            tr.data      = 32'(0);          //first beat data
            tr.strb      = 1;
            tr.has_bresp = 1;
            tr.has_rresp = 0;
            start_item(tr);
            finish_item(tr);
        
        ////2)Optionally, do read_back of the same address
            if(do_readback) begin
            axi4_txn rd;
            rd = axi4_txn::type_id::create("rd");

            rd.txn_type  = TXN_READ;
            rd.addr      = addr;
            rd.len       = num_beats - 1;   //AXI len = beats - 1
            rd.has_bresp = 0;
            rd.has_rresp = 1;
            start_item(rd);
            finish_item(rd);
            end
        endtask
        
    
endclass
`endif