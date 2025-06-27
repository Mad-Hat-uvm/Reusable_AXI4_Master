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
//Internal field for coverage sampling
//---------------------------------------------------------
   bit [1:0] cv_bresp;
   bit [1:0] cv_rresp;

//---------------------------------------------------------
//Optional coverage for response codes (BRESP, RRESP)
//---------------------------------------------------------
   covergroup resp_cg @(posedge clk);
    option.per_instance = 1;
    bresp_cp : coverpoint cv_bresp {
        bins OKAY     = {2'b00};
        bins EXOKAY   = {2'b01};
        bins SLVERR   = {2'b10};
        bins DECERR   = {2'B11};
    }

    rresp_cg : coverpoint cv_rresp {
        bins OKAY     = {2'b00};
        bins EXOKAY   = {2'bo1};
        bins SLVERR   = {2'b10};
        bins DECERR   = {2'b11};
    }
   endgroup
   resp_cg cg;

   //Clock handle for coverage sampling
   virtual logic clk;

//---------------------------------------------------------
//Constructor
//---------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);

        analysis_export = new("analysis_export", this);
       
    endfunction

//---------------------------------------------------------
//build_phase: grab clock for covergroup
//---------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual logic)::get(this, "", "clk", clk))
          `uvm_fatal("NOCLOCK", "axi4_scoreboard: clock not found in config DB");
        cg = new(this);  //instantiate per instance
    endfunction

//---------------------------------------------------------
//run_phase: consume and check forever
//---------------------------------------------------------
    task run_phase(uvm_phase phase);
        axi4_txn txn;
        forever begin
            //1) Get next transaction
            analysis_export.get(txn);

            if(txn.txn_type -- TXN_WRITE) begin
                //2a)Write: update the golden model
                ref_mem[txn.addr] = txn.data;

                //3a) Coverage on BRESP if provided
                if(txn.has_bresp) begin
                    cv_bresp = txn.bresp;
                    cg.bresp_cp.sample();
                end
            end
            else begin
                //2b) Read: compare against golden model
                data_t expected = ref_mem.exists[txn.addr] ? ref_mem[txn.addr] : `0;

                if(expected !== txn.data) begin
                    `uvm_error("AXI_SCB", $sformatf("Read mismatch @0x%0h: exp=0x%0h got=0x%0h", txn.addr, expected, txn.data));
                end
                //3b) Coverage on RRESP if provided
                if(txn.has_rresp) begin
                    cv_rresp = txn.rresp;
                    cg.rresp_cp.sample();
                end
            end
        end
    endtask


    