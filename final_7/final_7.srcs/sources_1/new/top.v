module demo_2(
    input clk,
    input rst,
    output reg [3:0] vgaRed,
    output reg [3:0] vgaGreen,
    output reg [3:0] vgaBlue,
    output hsync,
    output vsync,
    inout PS2_DATA,
    inout PS2_CLK,
    output [15:0] led,
    output audio_mclk,
    output audio_lrck,
    output audio_sck,
    output audio_sdin
);

parameter [8:0] KEY_CODES [0:3] = {
    9'b0_0001_1101, // W
    9'b0_0001_1100, // A
    9'b0_0001_1011, // S
    9'b0_0010_0011  // D
};

wire [11:0] data;
wire clk_25MHz;
wire clk_22;
wire [16:0] pixel_addr;
wire [11:0] pixel;
wire valid;
wire [9:0] h_cnt; //640
wire [9:0] v_cnt;  //480

wire [63:0] key_down;
wire [8:0] last_change;
wire key_valid;

wire [2:0] print_what;
parameter PRINT_COLOR = 2'd0;
parameter PRINT_LUCY = 2'd1;
parameter PRINT_BACKGROUND = 2'd2;
parameter PRINT_INIT_TITLE = 3'd3;
parameter PRINT_END_TITLE = 3'd4;
parameter PRINT_SPACE = 3'd5;
parameter PRINT_CROWN = 3'd6;
parameter PRINT_RESTART = 3'd7;

wire [12:0] lucy_pixel_addr;
wire [11:0] lucy_pixel;
wire [16:0] background_pixel_addr;
wire [11:0] background_pixel;
wire [11:0] init_title_pixel_addr;
wire [11:0] init_title_pixel;
wire [11:0] end_title_pixel_addr;
wire [11:0] end_title_pixel;
wire [9:0] space_pixel_addr;
wire [11:0] space_pixel;
wire [5:0] crown_pixel_addr;
wire [11:0] crown_pixel;
wire [9:0] restart_pixel_addr;
wire [11:0] restart_pixel;

wire [15:0] audio_in_left, audio_in_right;

wire [11:0] ibeatNum;
wire [31:0] freqL, freqR;
wire [21:0] freq_outL, freq_outR;

wire [2:0] state;

wire myclk123bpm;

my_clock_divider #(
    .DIVISOR(28'd3048780)
) myclkdiv1 (
    .clock_in(clk),
    .clock_out(myclk123bpm)
);

player_control #(.LEN(768)) playerCtrl_00 ( 
    .clk(myclk123bpm),
    .reset(rst),
    ._play(1'b1),
    ._slow(1'b0), 
    ._mode(1'b0),
    .state(state),
    .ibeat(ibeatNum)
);

music_example music_00 (
    .ibeatNum(ibeatNum),
    .en(1'b1),
    .state(state),
    .toneL(freqL),
    .toneR(freqR)
);

assign freq_outL = 50000000 / freqL;
assign freq_outR = 50000000 / freqR;

note_gen noteGen_00(
    .clk(clk), 
    .rst(rst), 
    .volume(3'b000),
    .note_div_left(freq_outL), 
    .note_div_right(freq_outR), 
    .audio_left(audio_in_left),     // left sound audio
    .audio_right(audio_in_right)    // right sound audio
);

speaker_control sc(
    .clk(clk), 
    .rst(rst), 
    .audio_in_left(audio_in_left),      // left channel audio data input
    .audio_in_right(audio_in_right),    // right channel audio data input
    .audio_mclk(audio_mclk),            // master clock
    .audio_lrck(audio_lrck),            // left-right clock
    .audio_sck(audio_sck),              // serial clock
    .audio_sdin(audio_sdin)             // serial audio data input
);

always @* begin
    if (valid == 1'b1) begin
        if (print_what == PRINT_LUCY)
        begin
            if (lucy_pixel == 12'hFFF) // white
                {vgaRed, vgaGreen, vgaBlue} = background_pixel;
            else
                {vgaRed, vgaGreen, vgaBlue} = lucy_pixel;
        end
        else if (print_what == PRINT_BACKGROUND)
        begin
            {vgaRed, vgaGreen, vgaBlue} = background_pixel;
        end 
        else if (print_what == PRINT_INIT_TITLE)
            {vgaRed, vgaGreen, vgaBlue} = init_title_pixel;
        else if (print_what == PRINT_SPACE)
            if (space_pixel == 12'h000) // black
                {vgaRed, vgaGreen, vgaBlue} = background_pixel;
            else
                {vgaRed, vgaGreen, vgaBlue} = space_pixel;
        else if (print_what == PRINT_END_TITLE)
            {vgaRed, vgaGreen, vgaBlue} = end_title_pixel;
        else if (print_what == PRINT_CROWN)
            {vgaRed, vgaGreen, vgaBlue} = crown_pixel;
        else if (print_what == PRINT_RESTART)
            if (restart_pixel == 12'h000) // black
                {vgaRed, vgaGreen, vgaBlue} = background_pixel;
            else
                {vgaRed, vgaGreen, vgaBlue} = restart_pixel;
        else
        begin
            {vgaRed, vgaGreen, vgaBlue} = pixel;
        end
    end 
    else
    begin
        {vgaRed, vgaGreen, vgaBlue} = 12'h0; 
    end
end

wire myclk25hz;

my_clock_divider #(
    .DIVISOR(28'd4000000)
) myclkdiv3 (
    .clock_in(clk),
    .clock_out(myclk25hz)
);

clock_divider #(
    .n(22)
) clk_wiz_0_inst(
    .clk(clk),
    .clk1(clk_25MHz),
    .clkDivn(clk_22)
);

mem_addr_gen mem_addr_gen_inst(
    .clk(myclk25hz),
    .rst(rst),
    .h_cnt(h_cnt),
    .v_cnt(v_cnt),
    .pixel_addr(pixel_addr),
    .pixel(pixel),
    .key_down(key_down),
    .last_change(last_change),
    .key_valid(key_valid),
    .led(led),
    .lucy_pixel_addr(lucy_pixel_addr),
    .background_pixel_addr(background_pixel_addr),
    .init_title_pixel_addr(init_title_pixel_addr),
    .space_pixel_addr(space_pixel_addr),
    .end_title_pixel_addr(end_title_pixel_addr),
    .crown_pixel_addr(crown_pixel_addr), 
    .restart_pixel_addr(restart_pixel_addr),
    .print_what(print_what),
    .state(state)
);
     
 
//    blk_mem_gen_0 blk_mem_gen_0_inst(
//      .clka(clk_25MHz),
//      .wea(0),
//      .addra(pixel_addr),
//      .dina(data[11:0]),
//      .douta(pixel)
//    ); 
blk_mem_gen_0 blk_mem_gen_0_inst(
      .clka(clk_25MHz),
      .wea(0),
      .addra(lucy_pixel_addr),
      .dina(data[11:0]),
      .douta(lucy_pixel)
    ); 
    
blk_mem_gen_1 blk_mem_gen_1_inst(
      .clka(clk_25MHz),
      .wea(0),
      .addra(background_pixel_addr),
      .dina(data[11:0]),
      .douta(background_pixel)
    ); 
    
blk_mem_gen_2 blk_mem_gen_2_inst(
      .clka(clk_25MHz),
      .wea(0),
      .addra(init_title_pixel_addr),
      .dina(data[11:0]),
      .douta(init_title_pixel)
    ); 

blk_mem_gen_3 blk_mem_gen_3_inst(
      .clka(clk_25MHz),
      .wea(0),
      .addra(end_title_pixel_addr),
      .dina(data[11:0]),
      .douta(end_title_pixel)
    ); 
    
blk_mem_gen_4 blk_mem_gen_4_inst(
      .clka(clk_25MHz),
      .wea(0),
      .addra(space_pixel_addr),
      .dina(data[11:0]),
      .douta(space_pixel)
    ); 
    
blk_mem_gen_5 blk_mem_gen_5_inst(
      .clka(clk_25MHz),
      .wea(0),
      .addra(crown_pixel_addr),
      .dina(data[11:0]),
      .douta(crown_pixel)
    ); 
    
blk_mem_gen_6 blk_mem_gen_6_inst(
      .clka(clk_25MHz),
      .wea(0),
      .addra(restart_pixel_addr),
      .dina(data[11:0]),
      .douta(restart_pixel)
    ); 

vga_controller   vga_inst(
    .pclk(clk_25MHz),
    .reset(rst),
    .hsync(hsync),
    .vsync(vsync),
    .valid(valid),
    .h_cnt(h_cnt),
    .v_cnt(v_cnt)
);

KeyboardDecoder(
    .rst(rst),
	.clk(clk),
	.PS2_DATA(PS2_DATA),
	.PS2_CLK(PS2_CLK),
	.key_down(key_down),
	.last_change(last_change),
	.key_valid(key_valid)
);

endmodule
