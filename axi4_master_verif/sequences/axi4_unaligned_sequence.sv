//-----------------------------------------------------------------------------
// axi4_unaligned_sequence.sv - Extend base sequence to allow custom 
//                              strobe patterns
//-----------------------------------------------------------------------------
`ifndef AXI4_UNALIGNED_SEQUENCE_SV
`define AXI4_UNALIGNED_SEQUENCE_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

import axi4_pkg::*;

class axi4_unaligned_sequence extends axi4_base_sequence;
    `uvm_object_utils(axi4_unaligned_sequence)

    //New public field: allow test to specify a custom strobe mask
     bit [DATA_WIDTH/8 - 1: 0] custom_strb;

//----------------------------------------------------------------------------   
//Constructor
//----------------------------------------------------------------------------
    function new(string name = "axi4_unaligned_sequence");
        super.new(name);
    endfunction

    virtual task body();
       //Build write with custom strobe
            axi4_txn wr;
            wr = axi4_txn::type_id::create("wr");

            wr.txn_type  = TXN_WRITE;
            wr.addr      = addr;
            wr.len       = num_beats - 1;   //AXI len = beats - 1
            wr.data      = `hDEAD_BEEF;     //  fixed pattern
            wr.strb      = custom_strb;     //use custom mask
            wr.has_bresp = 1;
           
            start_item(rd);
            finish_item(rd);

            if(do_readback) begin
            axi4_txn rd;
            rd = axi4_txn::type_id::create("rd");

            rd.txn_type  = TXN_READ;
            rd.addr      = addr;
            rd.len       = num_beats - 1;   //AXI len = beats - 1
            rd.has_rresp = 1;
            start_item(rd);
            finish_item(rd);
            end
           
    endtask: axi4_unaligned_sequence