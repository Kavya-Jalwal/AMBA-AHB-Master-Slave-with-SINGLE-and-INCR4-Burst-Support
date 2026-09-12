module TB2yt(

    );
    reg clk,rst;
    reg [31:0] data_top;
    reg write_top;
    reg wrap_enb;
    wire hready,hresp;
    wire [31:0] hrdata;
    reg enb;
    reg[31:0] addr_top;
    wire [31:0] HADDR;
    wire HWRITE;
    wire [2:0] HSIZE;
    wire [2:0] HBURST;
    wire [1:0] HTRANS;
    wire [31:0] HWDATA;
    reg [3:0] beat_length;
    wire fifo_empty,fifo_full;
    master_ahb dut(clk,rst,hready,hresp,hrdata,data_top,write_top,beat_length,enb,addr_top,wrap_enb,
    HADDR,HWRITE,HSIZE,HWDATA,HBURST,HTRANS);
    slave_ahbyt dut2(clk,rst,HADDR,HWRITE,HSIZE,HBURST,HTRANS,HWDATA,hready,hresp,hrdata);
    initial begin
    clk = 0;
    rst = 1;
    data_top = 0;
    write_top = 0;
    wrap_enb = 0;
    enb = 0;
    addr_top = 0;
    beat_length = 0;
    end
    always #5 clk=~clk;
    initial begin
       rst=1;
       #10;
       rst=0;
//       if(!fifo_full)
//       begin
       write_top=1;
       addr_top=32'h0000_0000;
       data_top=32'h0000_0000;
       #10;
       data_top=32'h1234_1234;
       #10;
       data_top=32'h0000_0002;
       #10;
       data_top=32'h0000_0003;
       beat_length=4;
       enb=1;
       wrap_enb=0;
       #20;
       enb=0;
//       end
    end
       
    
endmodule
