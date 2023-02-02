module player_control (
	input clk, 
	input reset, 
	input _play, 
	input _slow, 
	input _mode, 
	input state,
	output reg [11:0] ibeat
);
	parameter LEN = 4095;
    reg [11:0] next_ibeat;
    
parameter INIT = 3'd0;
parameter GAME = 3'd1;
parameter END = 3'd2;

	always @(posedge clk, posedge reset) begin
		if (reset) begin
			ibeat <= 0;
		end else begin
            ibeat <= next_ibeat;
		end
	end

    always @* begin
        next_ibeat = (ibeat + 1 < LEN) ? (ibeat + 1) : 0;
    end

endmodule
