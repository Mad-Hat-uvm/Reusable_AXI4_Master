//----------------------------------------------------------------
// AXI4 Scoreboard
//   • Analysis export to connect to monitor’s ap
//   • Golden reference model (array) for writes/reads
//   • Read/write checks with UVM reporting
//   • Functional coverage on BRESP/RRESPl
//----------------------------------------------------------------
`ifndef AXI4_SCOREBOARD_SV
`define AXI4_SCOREBOARD_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import axi4_pkg::*;

class axi4_scoreboard extends uvm_component;
    `uvm_component_utils(axi4_scoreboard)

//---------------------------------------------------------
//Analysis export receives transactions from monitor
//---------------------------------------------------------
    uvm_analysis_export #(axi4_txn, axi4_scoreboard) analysis_export;
   
//---------------------------------------------------------
//Golden memory: associative array keyed by address
//---------------------------------------------------------
    typedef bit [DATA_WIDTH-1 : 0] mem_t[int unsigned];
   mem_t ref_mem;  //associative array indexed by address

//---------------------------------------------------------
//Optional coverage for response codes (BRESP, RRESP)
//---------------------------------------------------------
   covergroup resp_cg @(posedge clk);
    option.per_instance = 1;
    bresp_cp : coverpoint 
   endgroup

//---------------------------------------------------------
//Constructor
//---------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);

        analysis_export = new("analysis_export", this);
       
    endfunction

    //Called when write monitor sends a transaction
    function void write(input axi_transaction tr);
        if(tr.txn_type == axi_transaction::AXI_WRITE) begin
            ref_mem[tr.addr] = tr.data;
            `uvm_info("AXI_SB_WRITE", $sformatf("Logged WRITE addr=0x%0h data=0x%0h", tr.addr, tr.data), UVM_MEDIUM)
        end 
        else begin
            `uvm_error("AXI_SB_WRITE", "Received non_write transaction on write export");
            
        end
    endfunction

     //Called when read monitor sends a transaction
    function void read(input axi_transaction tr);
        bit [31:0] expected;

        if(tr.txn_type == axi_transaction::AXI_READ) begin
          if(ref_mem.exists(tr.addr)) begin
            expected = ref_mem[tr.addr];
            if(expected != tr.data)
            `uvm_error("AXI_SB_READ", $sformatf("Read MISMATCH at 0x0%h: expected: 0x0%h actual=0x0%h", tr.addr, expected, tr.data))
            else
            `uvm_info("AXI_SB_READ", $sformatf("Read MATCH at 0x%0h: data=0x%0h", tr.addr, tr.data), UVM_MEDIUM)
          end 
          else begin
            `uvm_warning("AXI_SB_READ", $sformatf("Read from UNWRITTEN addr=0x%0h", tr.addr));
          end
        end
        else begin
            `uvm_error("AXI_SB_READ", "Received non_write transaction on write export");
        end
    endfunction


endclass