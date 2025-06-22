//------------------------------------------------------------------------------
//AXI4 interface
// - Synchronous clocking blocks for cycle-accurate stimulus & monitoring
// - Default timing annotations (#1step) inside clocking blocks
// - Separate master/slave modports that import the appropriate clocking block
//------------------------------------------------------------------------------
interface axi_if #(parameter ADDR_WIDTH = 32, DATA_WIDTH = 32, parameter ID_WIDTH = 4, parameter STRB_WIDTH = DATA_WIDTH/8)
                  (input logic ACLK,  //Global clocks for all AXI channels
                  input logic ARESETn //Active-low synchronous reset
                  );

//---------------------------------------------------------
//Write Address Channel
//---------------------------------------------------------
logic [ADDR_WIDTH-1 : 0] AWADDR;    //Write address
logic                    AWLEN;     //Burst length: #beats = AWLEN + 1
logic [1:0]              AWBURST;   //Burst type: 00=FIXED, 01=INCR, 10=WRAP
logic [ID_WIDTH-1 : 0]   AWID;      //Transaction ID                  
logic                    AWVALID;   //Write address valid
logic                    AWREADY;   //Write address ready (slave)

//---------------------------------------------------------
//Write Data Channel
//---------------------------------------------------------
logic [DATA_WIDTH-1 : 0] WDATA;     //Write Data
logic [STRB_WIDTH-1 : 0] WSTRB;     //Byte-enable strobes
logic                    WLAST;     //Last beat indicator
logic                    WVALID;    //Write Data Valid
logic                    WREADY;    //Write Data Ready (slave)

//---------------------------------------------------------
//Write Response Channel
//---------------------------------------------------------
logic [ID_WIDTH-1 : 0]   BID;        //Echoed AWID of the completed write
logic [1:0]              BRESP;     //Write Response (OKAY, SLVERR, etc.)
logic                    BVALID;    //Write Response Valid
logic                    BREADY;    //Write Response Ready (master)

//---------------------------------------------------------
//Read Address Channel
//---------------------------------------------------------
logic [ADDR_WIDTH-1 : 0] ARDDR;     //Read Address
logic [7:0]              ARLEN;     //Burst length: #beats = ARLEN + 1
logic [1:0]              ARBURST;   //Burst type: 00=FIXED, 01=INCR, 10=WRAP
logic [ID_WIDTH-1 : 0]   ARID;      //Transaction ID
logic                    ARVALID;   //Read Address Valid
logic                    ARREADY;   //Read Address ready (slave)

//---------------------------------------------------------
//Read Data Channel
//---------------------------------------------------------
logic [ID_WIDTH-1 : 0]   RID;       //Echoed ARID for this read
logic [DATA_WIDTH-1 : 0] RDATA;     //Read Data
logic [1:0]              RRESP;     //Read Response
logic                    RLAST;     //Last beat indicator
logic                    RVALID;    //Read Data Valid
logic                    RREADY;    //Read Data Ready(master)

//---------------------------------------------------------
//MASTER Clocking Block
// - Used by the UVM master agent to drive AW/W/AR channels and sample B/R
// - Introduces a 1-step delta delay for both driving and sampling
//---------------------------------------------------------
clocking master_cb @ (posedge clk);
   //Apply default 1-step delay for all inputs/outputs
    default input #1step output #1step;
    
    //Allow reset sampling
    input ARESETn;

    //AW channel: master drives write address, slave's ready is sampled
    output AWADDR, AWVALID, AWLEN, AWBURST, AWID;
    input AWREADY;

    //W channel: master drives data, slave's ready is sampled
    output WDATA, WVALID, WLAST, WSTRB;
    input WREADY;

    //B channel: slave drives response, master drives BREADY
    input BID, BRESP, BVALID;
    output BREADY;

    //AR channel: master drives read address, slave's ready is sampled
    output ARADDR, ARVALID, ARLEN, ARBURST, ARID;
    input ARREADY;

    //R channel: slave drives read data, master drives RREADY
    input RDATA, RID, RVALID, RRESP, RLAST;
    output RREADY;
endclocking

//---------------------------------------------------------
//SLAVE Clocking Block
// - Used by the DUT to drive B/R channels and sample AW/W/AR
// - Also uses a 1-step delta delay for consistency
//---------------------------------------------------------
clocking slave_cb @ (posedge clk);
   //Apply default 1-step delay for all inputs/outputs
    default input #1step output #1step;
    
    //Allow reset sampling
    input ARESETn;

    //AW channel: slave samples AW*, master's valid is input
    input AWADDR, AWVALID, AWLEN, AWBURST, AWID;
    output AWREADY;

    //W channel: slave samples W*, master's valid is sampled
    input WDATA, WVALID, WLAST, WSTRB;
    output WREADY;

    //B channel: slave drives response, master's ready is input
    output BID, BRESP, BVALID;
    input BREADY;

    //AR channel: slave samples AR*, MASTER's ready is input
    input ARADDR, ARVALID, ARLEN, ARBURST, ARID;
    output ARREADY;

    //R channel: slave drives data, master's ready is input
    output RDATA, RID, RVALID, RRESP, RLAST;
    input RREADY;
endclocking

//--------------------------------------------------------------------------
//MODPORTS
// - Expose the appropriate clocking block to consumers
// - UVM env uses `modport MASTER`; DUT instantiates with `modport SLAVE`
//--------------------------------------------------------------------------
modport MASTER (import master_cb);
modport SLAVE (import slave_cb);

endinterface