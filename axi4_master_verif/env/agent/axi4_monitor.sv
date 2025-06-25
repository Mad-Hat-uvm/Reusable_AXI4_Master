

//----------------------------------------------------------------
// AXI4 Monitor
//  • Samples all five AXI4 channels via clocking block
//  • Reconstructs complete transactions (address + data beats)
//  • Emits each transaction once, letting axi4_txn.cg handle coverage
//  • Sends transactions to a scoreboard or coverage collector via analysis port
//----------------------------------------------------------------
`ifndef AXI4_MONITOR_SV
`define AXI4_MONITOR_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

import axi4_pkg::*;

class axi4_monitor extends uvm_monitor;
 `uvm_component_utils(axi4_monitor)

//-------------------------------------------------------------
// Virtual Interface Handle
//-------------------------------------------------------------
    virtual axi4_if.MASTER vif;

//-------------------------------------------------------------
//Analysis port to broadcast observed transactions
//-------------------------------------------------------------
    
    uvm_analysis_port #(axi4_txn) mon_ap;

//-------------------------------------------------------------
//Constructor
//-------------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);
        mon_ap = new("mon_ap", this);
    endfunction

//-------------------------------------------------------------
//Build phase: get virtual interface from config_db
//-------------------------------------------------------------
   function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db#(virtual axi4_if.MASTER)::get(this, "", "vif", vif))
        `uvm_fatal("AXI4_monitor", "Virtual interface not found")
        
    endfunction

    //Run phase: Launch forked monitors
    task run_phase(uvm_phase phase);
        fork
            monitor_write_channel();
            monitor_read_channel();
        join_none
        //This task never returns-both forks run forever
    endtask

//----------------------------------------------------------------
// Monitor AXI4 write transaction (AW -> W -> B)
//----------------------------------------------------------------
task monitor_write_channel();
    axi4_txn tr;

    forever begin
        //Wait for AW handshake
        @(posedge vif.master_cb.ACLK);
       wait (vif.master_cb.AWVALID && vif.master_cb.AWREADY);

       //Build the write transaction
        tr = axi4_txn::type_id::create("tr", this);
        tr.txn_type = axi4_txn::TXN_WRITE;
        tr.addr  = vif.master_cb.AWADDR;
        tr.len   = vif.master_cb.AWLEN;
        tr.burst = vif.master_cb.AWBURST;
        tr.id    = vif.master_cb.AWID;
        tr.strb  = `0;  

        //Capture all data beats
        for(int beat = 0; beat <= txn.len; beat++) begin
        @(posedge vif.master_cb.ACLK); 
        wait (vif.master_cb.WVALID && vif.master_cb.WREADY);
        tr.data  = vif.master_cb.WDATA;
        tr.strb |= vif.master_cb.WSTRB;
        tr.last  = vif.master_cb.WLAST;
        wait (!vif.master_cb.WVALID);
        end
        //Sample coverage and publish
        tr.cg.sample();
        mon_ap.write(tr);

        //Capture B response
         if (vif.master_cb.BVALID && vif.master_cb.BREADY);
        tr.resp = vif.master_cb.BRESP;

        `uvm_info("AXI_MON_WRITE", $sformatf("Sample write: %s",tr.convert2string()), UVM_MEDIUM)

        //Send transaction to scoreboard
        mon_ap.write(tr);
        
    end
endtask

//----------------------------------------------------------------
// Monitor Read transactions(AR -> R)
//----------------------------------------------------------------
task monitor_read_channel();
    axi4_txn tr;

    forever begin
        //Wait for AR handshake
        @(posedge vif.master_cb.ACLK);
        wait (vif.master_cb.ARVALID && vif.master_cb.ARREADY);

        //Build the read transaction
        tr = axi4_txn::type_id::create("tr", this);
        tr.txn_type = axi4_txn::TXN_READ;
        tr.addr     = vif.master_cb.ARADDR;
        tr.len      = vif.master_cb.ARLEN;
        tr.burst    = vif.master_cb.ARBURST;
        tr.id       = vif.master_cb.ARID;


        //Capture all beats
        for(int beat = 0; beat <= tr.len; beat++) begin
        @(posedge vif.master_cb.ACLK);
        wait (vif.master_cb.RVALID && vif.master_cb.RREADY);
        tr.data = vif.master_cb.RDATA;
        tr.resp = vif.master_cb.RRESP;
        wait(!vif.master_cb.RVALID);
        end

        //Sample coverage and publish
        tr.cg.sample();
        mon_ap.write(tr);

        `uvm_info("AXI_MON_READ", $sformatf("Sample read: %s",tr.convert2string()), UVM_MEDIUM)
        
        end
        
    
endtask

endclass

