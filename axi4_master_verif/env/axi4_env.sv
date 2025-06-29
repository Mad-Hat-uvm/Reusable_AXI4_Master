//---------------------------------------------------------
//axi4_env.sv - Industry-Grade UVM Environment for AXI4
//---------------------------------------------------------
`ifndef AXI4_ENV_SV
`define AXI4_ENV_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

import axi4_pkg::*;

class axi4_env extends uvm_env;
    `uvm_component_utils(axi4_env)

//---------------------------------------------------------
//Sub - components
//---------------------------------------------------------
    axi4_agent      agent;
    axi4_scoreboard scoreboard;
    axi4_coverage   coverage; //dedicated coverage collector

//---------------------------------------------------------
//Constructor
//---------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

//---------------------------------------------------------
//Build-phase
//---------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(uvm_phase phase);

        //Create the agent(active by default)
        agent      = axi4_agent::type_id::create("agent", this);
        
        //Create the scoreboard(protocol correctness + low-level covergroup)
        scoreboard = axi4_scoreboard::type_id::create("scoreboard", this);

        //Crate coverage collector(higher-level metrics)
        coverage   = axi4_coverage::type_id::create("coverage", this);

        //Bind the DUT clock for sampling covergroups in scoreboards and coverage
        virtual logic clk;
        if (!uvm_config_db#(virtual logic)::get(this, "agent", "vif.ACLK", clk)) begin
            `uvm_fatal("NOCLOCK", "Failed to get ACLK for coverage")
        end
        uvm_config_db#(virtual logic)::set(this, "scoreboard", "clk", clk);
        uvm_config_db#(virtual logic)::set(this, "coverage", "clk", clk);

        //(Optional) set agent to passive in certain tests:
        //uvm_config_db#(bit)::set(this, "agent", "is_active", 0);
    endfunction

//---------------------------------------------------------
//Connect Phase: wire agent -> scoreboard, coverage, etc.
//---------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        super.connect_phase(uvm_phase phase);
        agent.monitor.mon_ap.connect(scoreboard.analysis_export);
        agent.monitor.mon_ap.connect(coverage.analysis_export);
    endfunction
endclass

`endif