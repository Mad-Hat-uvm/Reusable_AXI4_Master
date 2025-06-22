//-------------------------------------------------------------
// AXI4 Transaction Class
// - UVM sequence item for AXI4master transactions
//-------------------------------------------------------------

package axi4_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

//-------------------------------------------------------------
// Strongly-typed aliases
//-------------------------------------------------------------
    typedef bit [ADDR_WIDTH-1 : 0] addr_t;
    typedef bit [DATA_WIDTH-1 : 0] data_t;
    typedef bit [ID_WIDTH-1 : 0]   id_t;
    typedef bit [STRB_WIDTH-1 : 0] strb_t;

//-------------------------------------------------------------
// Burst-type enumeration
//------------------------------------------------------------- 
    typedef enum bit [1:0] {
      FIXED = 2'b00;
      INCR  = 2'b01;
      WRAP  = 2'b10;
    } burst_t; 

//-------------------------------------------------------------
// Enum: Transaction type (Read/Write)
//-------------------------------------------------------------
    typedef enum bit {
      TXN_WRITE = 1'b0,
      TXN_READ  = 1'b1
    }txn_type_t;

//-------------------------------------------------------------
// AXI4 transaction: read or write
//------------------------------------------------------------- 
class axi4_txn extends uvm_sequence_item;

//-------------------------------------------------------------
// Fields
//-------------------------------------------------------------
rand addr_t     addr;         //Base address
rand data_t     data;         //Write data(ignore on read)
rand byte       len;          //Burst length = len+1 beats
rand burst_t    burst;        //Burst type
rand id_t       id;           //Transaction ID
rand strb_t     strb;         //Byte-enable mask
rand txn_type_t txn_type;     //READ or WRITE

//-------------------------------------------------------------
// Coverage
//-------------------------------------------------------------
covergroup cg;
    coverpoint burst;
    coverpoint len {
        bins small = {[0:3]};
        bins large = {[4:15]}
    }
endgroup

//-------------------------------------------------------------
//Constructor
//-------------------------------------------------------------
function new(string name = "axi4_txn");
 super.new(name);
 cg = new(this);
endfunction


//-------------------------------------------------------------
// Constraints
//-------------------------------------------------------------
constraint strb_nonzero {
    (txn_type == TXN_WRITE) -> (STRB != 0);  //WRITES must enable at least 1 byte
}

constraint len_values { len inside {1, 3, 7, 15}; }  //constrain len to power of 2 or specific supported values

//-------------------------------------------------------------
//Factory Registration
//-------------------------------------------------------------
`uvm_object_utils_begin(axi4_txn)
  `uvm_field_enum(txn_type, UVM_ALL_ON)
  `uvm_field_int(addr,      UVM_ALL_ON)
  `uvm_field_int(data,      UVM_ALL_ON)
  `uvm_field_int(id,        UVM_ALL_ON)
  `uvm_field_int(burst,     UVM_ALL_ON)
  `uvm_field_int(len,       UVM_ALL_ON)
  `uvm_field_int(strb,      UVM_ALL_ON)
`uvm_object_util_end



//-------------------------------------------------------------
//Convert to String (Debug)
//-------------------------------------------------------------
function string convert2string();
    return $sformatf("AXI4_TXN: %s id=%0d ADDR=0x%0H DATA=0x%08x LEN=%0d BURST=%0d STRB=0X%0h",
                    (txn_type == TXN_READ) ? "READ" : "WRITE",
                    id, addr, data, len+1, burst, strb);
endfunction: convert2string


endclass

endpackage