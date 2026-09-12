module slave_ahbyt(
 input HCLK,
 input HRESET,
 input [31:0] HADDR,
 input HWRITE,
 input [2:0] HSIZE,
 input [2:0] HBURST,
 input [1:0] HTRANS,
 input [31:0] HWDATA,
 output reg HREADY,
 output HRESP,
 output reg [31:0] HRDATA
    );
  parameter idle=2'b00;
  parameter sample_state=2'b01;
  parameter write_state=2'b10;
  parameter write_state_ready=2'b11;
  reg [1:0] htrans_internal;
  reg hwrite_internal;
  reg [31:0] addr_internal;
  reg [1:0] ps,ns; //present and next state
  //present state logic
  always @(posedge HCLK) begin
    if(HRESET) begin 
      ps<=idle;
      HRDATA<=32'b0;
    end
    else ps<=ns;
  end
  //next state logic
  always @(*) begin
    ns = ps;
    HREADY = 1'b1;
    HRDATA = 32'b0;
    case(ps)
      idle:begin
        HREADY=1;
        ns=sample_state;
      end
      sample_state:begin
        htrans_internal=HTRANS;
        hwrite_internal=HWRITE;
        addr_internal=HADDR;
        if(htrans_internal ==2'b10 || htrans_internal==2'b11) begin
          if(hwrite_internal)
            ns=write_state;
        end
      end
      write_state: begin
         HRDATA=HWDATA;
         if(htrans_internal==2'b00)
           ns=idle;
      end
      endcase
      end
      assign HRESP=1'B0;
endmodule
