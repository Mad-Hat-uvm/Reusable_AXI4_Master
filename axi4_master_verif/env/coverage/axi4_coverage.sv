//----------------------------------------------------------------
// AXI4 Coverage Collector
//----------------------------------------------------------------
`ifndef AXI4_COVERAGE_SV
`define AXI4_COVERAGE_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import axi4_pkg::*;

class axi4_coverage extends uvm_component;
    `uvm_component_utils(axi4_coverage)

//---------------------------------------------------------
//Analysis export receives transactions from monitor
//---------------------------------------------------------
    uvm_analysis_export #(axi4_txn, axi4_coverage) analysis_export;

//Clock handle for coverage sampling
   virtual logic clk;

//---------------------------------------------------------
//Covergroup: Address Range
//---------------------------------------------------------
  covergroup cg_addr @(posedge clk);
    coverpoint txn.addr {
    bins addr_0_1k   = {[0 : 1023]};
    bins addr_1k_4k  = {[1024 : 4095]};
    bins addr_4k_up  = {[4096 : 2**32 - 1]};
    }
  endgroup

//---------------------------------------------------------
//Covergroup: transaction length
//---------------------------------------------------------
   covergroup cg_len @(posedge clk);
    coverpoint txn.len {
    bins len_1 = {1};
    bins len_2 = {2};
    bins len_4 = {4};
    bins len_8 = {8};
    bins len_16plus = {[16:$]};
    }
   endgroup

//---------------------------------------------------------
//Covergroup: Data pattern
//---------------------------------------------------------
   covergroup cg_data @(posedge clk);
    option.per_instance = 1;
    coverpoint txn.data {
        bins all_zero  = {32'h0000_0000};
        bins all_ones  = {32'hFFFF_FFFF};
        bins alt_bits  = {32'hAAAA_AAAA, 32'h5555_5555};
        bins random    = default;
    }
   endgroup
    
   covergroup cg_resp @(posedge clk);
    coverpoint txn.bresp {
        bins OKAY     = {2'b00};
        bins EXOKAY   = {2'bo1};
        bins SLVERR   = {2'b10};
        bins DECERR   = {2'b11};
    }

    coverpoint txn.rresp {
        bins OKAY     = {2'b00};
        bins EXOKAY   = {2'bo1};
        bins SLVERR   = {2'b10};
        bins DECERR   = {2'b11};
    }
   endgroup

//---------------------------------------------------------
//Cross-coverage: length v/s Read-response
//---------------------------------------------------------
  covergroup cg_cross @(posedge clk);
    cross cg_len.txn.len, cg_resp.txn.rresp;
  endgroup
   
//---------------------------------------------------------
//Constructor
//---------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);

        analysis_export = new("analysis_export", this);
       
    endfunction

//---------------------------------------------------------
//build_phase: grab the clock and create covergroup instances
//---------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual logic)::get(this, "", "clk", clk))
          `uvm_fatal("NOCLOCK", "axi4_coverage: clock not found in config DB");


        cg_addr = new(this);
        cg_len = new(this);
        cg_data = new(this);
        cg_resp = new(this);
        cg_cross = new(this);  
    endfunction

//---------------------------------------------------------
//run_phase: consume and check forever
//---------------------------------------------------------
    task run_phase(uvm_phase phase);
        axi4_txn txn;
        forever begin
            // Get next transaction
            analysis_export.get(txn);

            cg_addr.sample();
            cg_len.sample();
            cg_data.sample();
            cg_resp.sample();
            cg_cross.sample();
        end
       
    endtask

    `endif 

    