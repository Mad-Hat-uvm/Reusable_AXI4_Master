//-------------------------------------------------------------
//AXI-4 Slave Register-FIle DUT
//- Supports full AXI-4: AW, W, B, AR, R channels
//- Burst types: INCR, FIXED, WRAP
//- ID tags, byte strobes, multi-beat transfers
//-------------------------------------------------------------

module axi4_slave_regfile #(parameter ADDR_WIDTH = 32, DATA_WIDTH = 32, ID_WIDTH = 4, STRB_WIDTH = DATA_WIDTH/8, NUM_REGS = 16)
(
    input logic ACLK,
    input logic ARESETn,

    //Write Address Channel
    input  logic [ADDR_WIDTH-1 : 0] AWADDR,
    input  logic                    AWVALID,
    input  logic [7:0]              AWLEN,
    input  logic [1:0]              AWBURST,
    input  logic [ID_WIDTH-1:0]     AWID,
    output logic                    AWREADY,

    //Write Data Channel
    input  logic [DATA_WIDTH-1 :0 ] WDATA,
    input  logic [STRB_WIDTH-1 : 0] WSTRB,
    input  logic                    WLAST,
    input  logic                    WVALID,
    output logic                    WREADY,

    //Write Response Channel
    output logic [ID_WIDTH-1 : 0]   BID,
    output logic [1:0]              BRESP,
    output logic                    BVALID,
    input  logic                    BREADY,

    //Read Address Channel
    input  logic  [ADDR_WIDTH-1 : 0] ARDDR,
    input  logic  [7:0]              ARLEN,
    input  logic  [1:0]              ARBURST,
    input  logic  [ID_WIDTH-1 : 0]   ARID,
    input  logic                     ARVALID,
    output logic                     ARREADY,

    //Read Data Channel
    output logic [ID_WIDTH-1 : 0]    RID,
    output logic [DATA_WIDTH-1 : 0]  RDATA,
    output logic [1:0]               RRESP,
    output logic                     RLAST,
    output logic                     RVALID,
    input logic                      RREADY
);

//---------------------------------------------------------
//Internal Register File storage
//---------------------------------------------------------
logic [DATA_WIDTH-1 : 0] regfile [0: NUM_REGS-1];

//---------------------------------------------------------
//Write-side state & Latches
//---------------------------------------------------------
    logic [ADDR_WIDTH-1 : 0] aw_addr;
    logic [7:0]              aw_len;
    logic [1:0]              aw_burst;
    logic [ID_WIDTH-1:0]     aw_id;
    logic [7:0]              w_count;
    logic                    aw_active;

//---------------------------------------------------------
//Read-side state & Latches
//---------------------------------------------------------
    logic [ADDR_WIDTH-1 : 0] ar_addr;
    logic [7:0]              ar_len;
    logic [1:0]              ar_burst;
    logic [ID_WIDTH-1:0]     ar_id;
    logic [7:0]              r_count;
    logic                    ar_active;

//---------------------------------------------------------
//Reset and AW/W/B channel FSM
//---------------------------------------------------------
always_ff @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn) begin
        //Reset Write side
        AWREADY   <= 0;
        WREADY    <= 0;
        BVALID    <= 0;
        BRESP     <= 0;
        BID       <= 0;
        aw_active <= 0;
        w_count   <= 0;
    end else begin
//---------------------------------------------------------
//AW Handshake and Latching
//---------------------------------------------------------
    if(!aw_active) begin
        if(AWVALID && !AWREADY) begin
         AWREADY   <= 1;
         aw_addr   <= AWADDR;
         aw_len    <= AWLEN;
         aw_burst  <= AWBURST;
         aw_id     <= AWID;
         aw_active <= 1'b1;
         w_count   <= 0;
        end else begin 
         AWREADY <= 0;
        end
    end

//---------------------------------------------------------
//W Handshake and Latching
//---------------------------------------------------------
    if(aw_active) begin
        if(WVALID && !WREADY) begin
         WREADY  <= 1'b1;
        end else begin
         WREADY  <= 1'b0;
        end

        if(WVALID && WREADY) begin
            //apply byte strobes
           for (int i = 0; i < STRB_WIDTH; i++) begin
            if(WSTRB[I])
             regfile[aw_addr[ $clog2(NUM_REG)-1 : 0]][8*i +: 8] <= WDATA[8*i +: 8] 
           end

           //advance/write-beat count & address
           if(w_count == aw_len) begin
            //last beat
            BVALID <= 1'b1;
            BRESP  <= 2'b00;
            BID    <= aw_id;
           end else begin
            w_count <= w_count + 1;
            //compute next address per burst type
            case (aw_burst)
                2'b00: aw_addr <= aw_addr;                  //FIXED
                2'b01: aw_addr <= aw_addr + STRB_WIDTH;     //INCR
                2'b10: aw_addr <= ( (aw_addr / (STRB_WIDTH*(aw_len+1))) * (STRB_WIDTH*(aw_len+1)) ) // WRAP
                                    + ((aw_addr + STRB_WIDTH) % (STRB_WIDTH*(aw_len+1)));
                default: aw_addr <= aw_addr;
            endcase
           end
        end

        //Clear BVALID when response is accepted
        end else if (BVALID && BREADY) begin
         BVALID    <= 0;                   //Complete response
         aw_active <= 0;
        end
    end
end


//---------------------------------------------------------
//Reset and AR/R channel FSM
//---------------------------------------------------------
always_ff @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn) begin
     //reset read side
        ARREADY   <= 0;
        RVALID    <= 0;
        RRESP     <= 0;
        RID       <= 0;
        ar_active <= 1'b0;
        r_count   <= 0;
        RLAST     <= 1'b0;
    end else begin
     //-------------------------------------------------
     //AR handshake & latching
     //-------------------------------------------------
        if(!ar_active) begin
        if(ARVALID && !ARREADY) begin
         ARREADY   <= 1;
         ar_addr   <= ARDDR;
         ar_len    <= ARLEN;
         ar_burst  <= ARBURST;
         ar_id     <= ARID;
         ar_active <= 1'b1;
         r_count   <= 0;
         RLAST     <= 1'b0;
        else
         ARREADY <= 0;
        end
    end
    //-------------------------------------------------
    //R data transfer
    //-------------------------------------------------
     if(ar_active) begin
        RVALID     <= 1'b1;
        RRESP      <= 2'b00;
        RID        <= ar_id;
        RDATA      <= regfile[ar_addr[$clog2[NUM_REG]-1 : 0]];

        if(r_count == ar_len)
        RLAST      <= 1'b1;

        if(RREADY && RVALID) begin
            //clear and finish when last beat seen
            if(RLAST) begin
                RVALID     <= 1'b0;
                ar_active  <= 1'b0;
            end else begin
            //advance beat and address
                r_count    <= r_count + 1;
                case(ar_burst)
                    2'b00: ar_addr  <= ar_addr;                    //FIXED
                    2'b01: ar_addr  <= ar_addr + STRB_WIDTH;
                    2'b10: ( (ar_addr / (STRB_WIDTH*(ar_len+1))) * (STRB_WIDTH*(ar_len+1)) ) // WRAP
                                   + ((ar_addr + STRB_WIDTH) % (STRB_WIDTH*(ar_len+1)));
                    default: ar_addr <= ar_addr;
                endcase
            end   
        end
     end
   end
end

       
endmodule