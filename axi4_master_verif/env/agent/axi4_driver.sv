//----------------------------------------------------------------
// axi4_driver.sv
// UVM Driver for AXI4 master agent
// - Drives AW/W/B or AR/R handshakes per transaction
// - Adopt clocking block for clean #1step timing
//----------------------------------------------------------------
`ifndef AXI4_DRIVER_SV
`define AXI4_DRIVER_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class axi4_driver extends uvm_driver #(axi4_txn);
    `uvm_component_utils(axi4_driver)

//-------------------------------------------------------------
// Virtual Interface Handle
//-------------------------------------------------------------
    virtual axi4_if.MASTER vif;

//-------------------------------------------------------------
// Constructor
//-------------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

//-------------------------------------------------------------
// Build phase
// Bind the interface
//-------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual axi4_if.MASTER)::get(this, "", "vif", vif))
          `uvm_fatal("AXI_DRV", "Virtual interface not set for axi4_driver")
    endfunction

//-------------------------------------------------------------
// Drive AXI4 transactions
//-------------------------------------------------------------
    task run_phase(uvm_phase phase);
        axi4_txn tr;

        forever begin
            //fetch next transaction from sequencer
            seq_item_port.get_next_item(tr);
             if(tr.txn_type == axi4_txn::TXN_WRITE)
              do_write(tr);
             else
              do_read(tr);

            seq_item_port.item_done(); //Notify sequencer
        end
    endtask

//---------------------------------------------------------
//Single beat or burst write
//---------------------------------------------------------
    task do_write(input axi4_txn tr);
        int beat;

        //Drive AW channel
        vif.master_cb.AWADDR  <= tr.addr;
        vif.master_cb.AWLEN   <= tr.awlen;
        vif.master_cb.AWBURST <= tr.burst;
        vif.master_cb.AWID    <= tr.id;
        vif.master_cb.AWVALID <= 1;
        wait (vif.master_cb.AWREADY);
        vif.master_cb.AWVALID <= 0;

        //Drive write beats
        for(beat = 0; beat <=tr.len; beat++) begin
        vif.master_cb.WDATA   <= tr.data;
        vif.master_cb.WSTRB   <= tr.strb;
        vif.master_cb.WLAST   <= (beat == tr.len);
        vif.master_cb.WVALID  <= 1;
        wait (vif.master_cb.WREADY);
        vif.WVALID  <= 0;
        end

        //Accept B response
        vif.master_cb.BREADY  <= 1;
        wait (vif.master_cb.BVALID);
        //optionally check BRESP
        vif.master_cb.BREADY  <= 0;

    `uvm_info("AXI4_WRITE_DRV", $sformatf("Write: %s", tr.convert2string()), UVM_MEDIUM)
endtask

//---------------------------------------------------------
//Single beat or burst read
//---------------------------------------------------------
task do_read(axi4_txn tr);
    int beat;

    //Drive AR channel
    vif.master_cb.ARADDR  <= tr.addr;
    vif.master_cb.ARLEN   <= tr.len;
    vif.master_cb.ARBURST <= tr.burst;
    vif.master_cb.ARID    <= tr.id;
    vif.master_cb.ARVALID <= 1;
    wait (vif.master_cb.ARREADY);
    vif.master_cb.ARVALID <= 0;

    //Collect read data
    vif.master_cb.RREADY  <= 1;
    for(beat = 0; beat <= tr.len + 1; beat++) begin
    wait (vif.master_cb.RVALID);
    tr.master_cb.data     <= vif.RDATA;
    tr.master_cb.resp     <= vif.RRESP;
    vif.master_cb.RREADY  <= 1;
    wait (!vif.master_cb.RVALID)
    vif.master_cb.RREADY  <= 0
    end
`uvm_info("AXI_READ_DRV", $sformatf("Read: %s", tr.convert2string()), UVM_MEDIUM)
endtask

endclass

`endif 