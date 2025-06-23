//-----------------------------------------------------------------------------
// axi4_agent.sv – Industry-Grade UVM AXI4 Master Agent
//   • Encapsulates sequencer, driver, and monitor
//   • Supports active (driver+monitor) and passive (monitor-only) modes
//   • Uses config-DB for interface binding and mode selection
//-----------------------------------------------------------------------------
`ifndef AXI4_AGENT_SV
`define AXI4_AGENT_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class axi4_agent extends uvm_agent;
    `uvm_component_utils(axi4_agent)

//---------------------------------------------------------
//Sub-components
//---------------------------------------------------------
    axi4_sequencer sequencer;
    axi4_driver    driver;
    axi4_monitor   monitor;

//---------------------------------------------------------
//Mode Flag: 1 = active (driver + monitor), 0 = passive (monitor only)
//---------------------------------------------------------
    bit is_active;

//---------------------------------------------------------
//Virtual interface handle (Master modport)
//---------------------------------------------------------
    virtual axi4_if.MASTER vif;

//---------------------------------------------------------
//Constructor
//---------------------------------------------------------
     function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

//---------------------------------------------------------
//Build Phase: instantiate sequencer, monitor, driver, bind interface
//---------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

    //Read active/passive mode from configDB (default = active)
        if(!uvm_config_db#(bit)::get(this, "", "is_active", is_active))
          is_active = 1;

    //Always create sequencer and monitor
            seqr     = axi4_sequencer::type_id::create("sequencer", this);
            monitor  = axi4_monitor::type_id::create("monitor", this);
        
    //Create driver only if active
            if(is_active)
           driver    = axi4_driver::type_id::create("driver", this);

    //Fetch virtual interface
           if(!uvm_config_db)#(virtual axi4_if.MASTER)::get(this, "", "vif", vif);
           `uvm_fatal("NOVIF", "AXI4_IF virtual interface not found in config DB")
    //Bind interfaces to sub-components
           uvm_config_db#(virtual axi4_if.Master)::set(this, "monitor", "vif", vif);
           if (is_active)
           uvm_config_db#(virtual axi4_if.Master)::set(this, "driver", "vif", vif);
    endfunction

//---------------------------------------------------------
// connect_phase: wire up driver↔sequencer and monitor↔scoreboard externally
//---------------------------------------------------------
    function connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        //Driver to sequencer
        if(is_active) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction
    

endclass

`endif