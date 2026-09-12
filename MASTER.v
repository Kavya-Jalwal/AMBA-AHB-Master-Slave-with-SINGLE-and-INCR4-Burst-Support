module master_ahb(
//AHB SIGNALS
input CLK_MASTER,
input RESET_MASTER,
input HREADY,
input HRESP,
input [31:0] HRDATA,
//USER DEFINED SIGNAL
input [31:0] data_top,//input to the master given by testbench
input write_top,//control signal for decoding write or read operation 
input [3:0] beat_length,
input enb,//enb=1 master will start either read or write operation
input [31:0] addr_top,//base address given from testbench
input wrap_enb,//wrap_enb=1 -> wrapping burst or it is an incr burst
//AHB OUTPUT SIGNALS
output [31:0] HADDR,//address bus
output reg HWRITE,//write control signal
output reg[2:0] HSIZE,//used for determining the transfer size
output reg [31:0] HWDATA,// DATA BUS
output reg [2:0] HBURST,
output reg [1:0] HTRANS,
//USER DEFINE SIGNAL(FIFO)
output fifo_empty,fifo_full );
reg [2:0] present_state,next_state;
reg [31:0] addr_internal=32'b0000_0000;
integer i=0;
reg [2:0] count=3'b000;
reg hburst_internal;
reg [31:0] internal_data;
reg [7:0] wrap_base;
reg [7:0] wrap_boundary;
reg [31:0] prev_address;
//fifo signals
reg [3:0] wr_ptr,rd_ptr;
reg [31:0] mem [15:0];
parameter idle=3'b000;
parameter write_state_address=3'b001;
parameter read_state_address=3'b010;
parameter read_state_data=3'b011;
parameter write_state_data=3'b100;
assign fifo_empty=(wr_ptr==rd_ptr);
assign fifo_full=(wr_ptr+1)==rd_ptr;
//fifo_reset_logic
always @(posedge CLK_MASTER)
  begin
    if(RESET_MASTER) begin
      for(i=0;i<16;i=i+1)
        mem[i]<=0;
        wr_ptr<=0;
       
     end
  else if(write_top && !fifo_full)begin
     mem[wr_ptr]<=data_top;
     wr_ptr<=wr_ptr+1'b1;
     end
  end
 //PRESENT STATE LOGIC
always @(posedge CLK_MASTER) begin

    if(RESET_MASTER) begin
        present_state <= idle;
        count <= 0;
        rd_ptr <= 0;
        addr_internal <= 0;
    end

    else begin

        present_state <= next_state;

        // Start INCR4 transaction or SINGLE
        if(present_state == idle &&
           write_top &&
           HREADY &&
           enb &&
           !wrap_enb) begin

            count <= 0;
            rd_ptr <= 0;
            addr_internal <= addr_top;

        end

        // Next INCR4 beat
        else if(present_state == write_state_data &&
                beat_length == 4 &&
                HREADY &&
                !wrap_enb) begin

            count <= count + 1'b1;
            rd_ptr <= rd_ptr + 1'b1;
            addr_internal <= addr_internal + 32'h4;

        end

    end
end
 //next state logic
 always @(*) begin
    next_state = present_state;
    HWRITE = 1'b0;
    HSIZE   = 3'b000;
    HBURST  = 3'b000;
    HTRANS  = 2'b00;
    HWDATA  = 32'b0;
   case(present_state)
     idle:begin
//       HSIZE='BX;
//       HBURST='BX;
//       HTRANS=2'B00;
//       HWDATA='BX;
//       count=0;
//       addr_internal=addr_top;
       //logic for write operation(SINGLE INCREMENTAL BURST)
       if(write_top && HREADY && beat_length==1 && enb && wrap_enb==0)begin
          next_state=write_state_address;
          HBURST=3'B000;
          HWRITE=1;
       end
       //logic for incr4 burst
       else if(write_top && HREADY && beat_length==4 && enb && wrap_enb==0)begin
          next_state=write_state_address;
          HBURST=3'B011;
          HWRITE=1;
       end
       end
     write_state_address: begin

    HSIZE  = 3'b010;
    HWRITE = 1'b1;

    // SINGLE transfer
    if(beat_length == 1) begin
        HBURST = 3'b000;
        HTRANS = 2'b10;
        next_state = write_state_data;
    end

    // INCR4 burst
    else if(beat_length == 4) begin
        HBURST = 3'b011;
        HTRANS = 2'b10;
        next_state = write_state_data;
    end

end
       write_state_data: begin

    HSIZE  = 3'b010;
    HWRITE = 1'b1;

    // SINGLE
    if(beat_length == 1) begin

        HBURST = 3'b000;
        HTRANS = 2'b10;
        HWDATA = data_top;

        if(HREADY)
            next_state = idle;

    end

    // INCR4
    else if(beat_length == 4) begin

        HBURST = 3'b011;
        HTRANS = 2'b11;
        HWDATA = mem[rd_ptr];

        if(count == beat_length-1)
            next_state = idle;
        else
            next_state = write_state_data;

    end

end
        default:next_state=idle;
   endcase   
   end  
   assign HADDR=addr_internal;   
endmodule
