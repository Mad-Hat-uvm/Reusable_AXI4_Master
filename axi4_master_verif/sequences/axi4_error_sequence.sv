//-----------------------------------------------------------------------------
// axi4_error_sequence.sv - Extend base sequence to allow custom 
//                              strobe patterns
//-----------------------------------------------------------------------------
`ifndef AXI4_ERROR_SEQUENCE_SV
`define AXI4_ERROR_SEQUENCE_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

import axi4_pkg::*;

class axi4_error_sequence extends axi4_base_sequence;
    `uvm_object_utils(axi4_error_sequence)

//----------------------------------------------------------------------------   
//Constructor
//----------------------------------------------------------------------------
    function new(string name = "axi4_error_sequence");
        super.new(name);
    endfunction

    virtual task body();
       //Intentionally use an invalid address
            axi4_txn wr;
            wr = axi4_txn::type_id::create("wr");

            wr.txn_type  = TXN_WRITE;
            wr.addr      = 32'hFFFF_FFFF;
            wr.len       = 0;   
            wr.data      = `hDEAD_BEEF;     //  fixed pattern
            wr.strb      = `1; 
            wr.has_bresp = 1;
           
            start_item(wr);
            finish_item(wr);

                    
    endtask: axi4_error_sequence