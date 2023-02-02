module mem_addr_gen(
    input clk,
    input rst,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    output [16:0] pixel_addr,
    output reg [11:0] pixel,
    input [63:0] key_down,
	input [8:0] last_change,
	input key_valid,
	output reg [15:0] led,
	output [12:0] lucy_pixel_addr,
	output [16:0] background_pixel_addr,
	output [11:0] init_title_pixel_addr,
	output [9:0] space_pixel_addr,
	output [11:0] end_title_pixel_addr,
	output [5:0] crown_pixel_addr,
	output [9:0] restart_pixel_addr,
	output [2:0] print_what,
	output [2:0] state
);

integer i;

reg [15:0] next_led;
assign pixel_addr = 0;

parameter obstacle_n = 31;
parameter signed [10:0] obstacle_pos_x [0:obstacle_n-1] = {
	11'd0,
	11'd157,
	11'd109, // top
	11'd37,
	11'd109,
	11'd115,
	11'd45,
	11'd109,
	11'd51,
	11'd109,
	11'd144,
	11'd98,
	11'd3,
	11'd45,
	11'd45,
	11'd3,
	11'd53,
	11'd96,
	11'd64,
	11'd141,
	11'd69,
	11'd106,
	11'd47,
	11'd3,
	11'd85,
	11'd136,
	11'd98,
	11'd61,
	11'd3,
	11'd117,
	11'd43
};
parameter signed [10:0] obstacle_pos_y [0:obstacle_n-1] = {
	11'd0,
	11'd0,
	11'd70, // top
	11'd100,
	11'd100,
	11'd100,
	11'd107,
	11'd150,
	11'd156,
	11'd157,
	11'd173,
	11'd186,
	11'd210,
	11'd210,
	11'd253,
	11'd310,
	11'd320,
	11'd356,
	11'd363,
	11'd376,
	11'd396,
	11'd396,
	11'd463,
	11'd470,
	11'd503,
	11'd503,
	11'd543,
	11'd586,
	11'd646,
	11'd646,
	11'd706
};
parameter signed [10:0] obstacle_size_x [0:obstacle_n-1] = {
	11'd3,
	11'd3,
	11'd14, // top
	11'd14,
	11'd6,
	11'd8,
	11'd6,
	11'd25,
	11'd8,
	11'd5,
	11'd13,
	11'd11,
	11'd18,
	11'd25,
	11'd25,
	11'd18,
	11'd19,
	11'd16,
	11'd48,
	11'd16,
	11'd17,
	11'd20,
	11'd18,
	11'd24,
	11'd25,
	11'd21,
	11'd33,
	11'd38,
	11'd40,
	11'd40,
	11'd74
};
parameter signed [10:0] obstacle_size_y [0:obstacle_n-1] = {
	11'd720,
	11'd720,
	11'd7, //top
	11'd7,
	11'd27,
	11'd7,
	11'd83,
	11'd7,
	11'd34,
	11'd59,
	11'd7,
	11'd30,
	11'd7,
	11'd7,
	11'd23,
	11'd7,
	11'd19,
	11'd7,
	11'd14,
	11'd8,
	11'd7,
	11'd8,
	11'd27,
	11'd21,
	11'd13,
	11'd13,
	11'd14,
	11'd21,
	11'd74,
	11'd74,
	11'd14
};

reg [7:0] win_point_pos_x = 8'd113;
reg [7:0] win_point_pos_y = 8'd64;
reg [7:0] win_point_size_x = 8'd5;
reg [7:0] win_point_size_y = 8'd4;

parameter [8:0] KEY_CODES [0:5] = {
    9'b0_0001_1101, // W
    9'b0_0001_1100, // A
    9'b0_0001_1011, // S
    9'b0_0010_0011, // D
    9'b0_0010_1101,  // R
    9'b0_0010_1001 // space 
};
parameter MAP_H = 11'd240;  // 480 -> 240 
parameter MAP_W = 11'd160;  // 640 -> 320
parameter LUCY_H = 11'd12;
parameter LUCY_W = 11'd9;
parameter MAP_INIT_Y = 11'd0;
parameter MAP_INIT_X = 11'd80;
parameter LUCY_INIT_Y = 11'd694;
parameter LUCY_INIT_X = 11'd80;
parameter signed [10:0] gravity = 1;
parameter signed [10:0] terminal_velocityY = 12;
parameter LEVEL_2 = 2'd2;
parameter LEVEL_1 = 2'd1;
parameter LEVEL_0 = 2'd0;

reg [1:0] level, next_level;
reg signed [10:0] offset_y;
reg signed [10:0] lucy_y, next_lucy_y;
reg signed [10:0] lucy_x, next_lucy_x;
reg signed [10:0] jumpValue = 0;
reg signed [10:0] next_jumpValue;
reg isGrounded;
reg signed [10:0] velocityY = 0;
reg signed [10:0] next_velocityY;
reg signed [10:0] velocityX = 0;
reg signed [10:0] next_velocityX;
reg delay_jumpValue;
reg delay_keyDownA;
reg delay_keyDownD;

// state
parameter INIT = 3'd0;
parameter GAME = 3'd1;
parameter END = 3'd2;
reg [2:0] state, next_state;

always @(posedge clk, posedge rst)
begin
    if (rst)
        state <= INIT;
    else
        state <= next_state;
end

always @*
begin
    case (state)
        INIT:
            if (key_down[KEY_CODES[5]])
                next_state = GAME;
            else
                next_state = INIT;
        GAME:
            if (lucy_x < win_point_pos_x && win_point_pos_x + win_point_size_x < lucy_x + LUCY_W && 
                lucy_y < win_point_pos_y && lucy_y + LUCY_H > win_point_pos_y + win_point_size_y)
                next_state = END;
            else
                next_state = GAME;
        END:
            if (key_down[KEY_CODES[4]])
                next_state = INIT;
            else
                next_state = END;
        default:
            next_state = INIT;
    endcase
end

// pictrans for lucy
reg [12:0] lucy_pixel_addr;

// pictrans for background
reg [16:0] background_pixel_addr;

// pictrans for initial title and end title
reg [11:0] init_title_pixel_addr;
reg [11:0] end_title_pixel_addr;
reg [9:0] space_pixel_addr;
reg [5:0] crown_pixel_addr;
reg [9:0] restart_pixel_addr;

// print what
reg [2:0] print_what;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        lucy_y <= LUCY_INIT_Y;
        lucy_x <= LUCY_INIT_X;
        velocityY <= 0;
        velocityX <= 0;
        jumpValue <= 0;
        led <= 0;
        delay_jumpValue <= 0;
        delay_keyDownA <= 0;
        delay_keyDownD <= 0;
        level <= LEVEL_0;
    end
    else 
    begin
        lucy_y <= next_lucy_y;
        lucy_x <= next_lucy_x;
        velocityY <= next_velocityY;
        velocityX <= next_velocityX;
        jumpValue <= next_jumpValue;
        led <= next_led;
        delay_jumpValue <= (jumpValue > 0);
        delay_keyDownA <= key_down[KEY_CODES[1]];
        delay_keyDownD <= key_down[KEY_CODES[3]];
        level <= next_level;
    end
end

// 
always @* begin
    //next_led = lucy_y;
    next_led[15] = lucy_x < win_point_pos_x;
    next_led[14] = win_point_pos_x + win_point_size_x < lucy_x + LUCY_W;
    next_led[13] = lucy_y < win_point_pos_y;
    next_led[12] = lucy_y + LUCY_H > win_point_pos_y + win_point_size_y;
    next_led[11:0] = lucy_y;
end

// Lucy Y
always @* begin
    if (state == GAME)
    begin
        next_lucy_y = lucy_y + velocityY;
        for(i=obstacle_n-1; i>=0; i=i-1) begin
            if(lucy_x + velocityX >= obstacle_pos_x[i] && lucy_x + velocityX < obstacle_pos_x[i] + obstacle_size_x[i] ||
               lucy_x + LUCY_W + velocityX > obstacle_pos_x[i] && lucy_x + LUCY_W + velocityX <= obstacle_pos_x[i] + obstacle_size_x[i] ||
               lucy_x + velocityX < obstacle_pos_x[i] && lucy_x + LUCY_W + velocityX > obstacle_pos_x[i] + obstacle_size_x[i]) begin
                if(velocityY > 0 && lucy_y + (LUCY_H) <= obstacle_pos_y[i] && lucy_y + velocityY + (LUCY_H) >= obstacle_pos_y[i]) begin
                    next_lucy_y = obstacle_pos_y[i] - (LUCY_H);
                end
                else if(velocityY < 0 && lucy_y >= obstacle_pos_y[i] + obstacle_size_y[i] && lucy_y + velocityY < obstacle_pos_y[i] + obstacle_size_y[i]) begin
                    next_lucy_y = obstacle_pos_y[i] + obstacle_size_y[i];
                end
            end
        end
    end
    else if (state == INIT)
        next_lucy_y = LUCY_INIT_Y;
    else
        next_lucy_y = lucy_y;
end

// Lucy X
always @* begin
    if (state == GAME)
    begin
        next_lucy_x = lucy_x + velocityX;
        for(i=0; i<obstacle_n; i=i+1) begin
            if(lucy_y + velocityY >= obstacle_pos_y[i] && lucy_y + velocityY < obstacle_pos_y[i] + obstacle_size_y[i] ||
               lucy_y + LUCY_H + velocityY > obstacle_pos_y[i] && lucy_y + LUCY_H + velocityY <= obstacle_pos_y[i] + obstacle_size_y[i] ||
               lucy_y + velocityY < obstacle_pos_y[i] && lucy_y + LUCY_H + velocityY > obstacle_pos_y[i] + obstacle_size_y[i]) begin
                if(velocityX > 0 && lucy_x + (LUCY_W) <= obstacle_pos_x[i] && lucy_x + velocityX + (LUCY_W) >= obstacle_pos_x[i]) begin
                    next_lucy_x = obstacle_pos_x[i] - (LUCY_W);
                end
                else if(velocityX < 0 && lucy_x >= obstacle_pos_x[i] + obstacle_size_x[i] && lucy_x + velocityX < obstacle_pos_x[i] + obstacle_size_x[i]) begin
                    next_lucy_x = obstacle_pos_x[i] + obstacle_size_x[i];
                end
            end
        end
    end
    else if (state == INIT)
        next_lucy_x = LUCY_INIT_X;
    else
        next_lucy_x = lucy_x;
end

// velocity Y
always @* begin
    if (state == GAME)
    begin
        if(!isGrounded) begin
            if(velocityY + gravity > terminal_velocityY) begin
                next_velocityY = terminal_velocityY;
            end
            else begin
                next_velocityY = velocityY + gravity;
            end
            for(i=0; i<obstacle_n; i=i+1) begin
                if(lucy_x + velocityX >= obstacle_pos_x[i] && lucy_x + velocityX < obstacle_pos_x[i] + obstacle_size_x[i] ||
                   lucy_x + LUCY_W + velocityX > obstacle_pos_x[i] && lucy_x + LUCY_W + velocityX <= obstacle_pos_x[i] + obstacle_size_x[i] ||
                   lucy_x + velocityX < obstacle_pos_x[i] && lucy_x + LUCY_W + velocityX > obstacle_pos_x[i] + obstacle_size_x[i]) begin
                    if(velocityY < 0 && lucy_y >= obstacle_pos_y[i] + obstacle_size_y[i] && lucy_y + velocityY < obstacle_pos_y[i] + obstacle_size_y[i]) begin
                        next_velocityY = -(velocityY + gravity);
                    end
                end
            end
        end
        else begin
            if(jumpValue >= 21) begin //  (x + 1) / 2
                next_velocityY = -11; 
            end
            else if(jumpValue > 0 && key_down[KEY_CODES[0]] == 0) begin // key_valid broken??
                next_velocityY = -((jumpValue+1)/2);
            end
            else begin
                if(delay_jumpValue) begin
                //if(velocityX == -2 || velocityX == 2) begin // delay_isGrounded 
                    next_velocityY = velocityY; // = velocityY ??, = 0 broken
                end
                else begin
                    next_velocityY = 0;
                end
            end
        end
    end
    else
        next_velocityY = 0;
end

// velocity X
always @* begin
    if (state == GAME)
    begin
        if(!isGrounded) begin // in the air
            next_velocityX = velocityX;
            for(i=0; i<obstacle_n; i=i+1) begin
                if(lucy_y + velocityY >= obstacle_pos_y[i] && lucy_y + velocityY < obstacle_pos_y[i] + obstacle_size_y[i] ||
                   lucy_y + LUCY_H + velocityY > obstacle_pos_y[i] && lucy_y + LUCY_H + velocityY <= obstacle_pos_y[i] + obstacle_size_y[i] ||
                   lucy_y + velocityY < obstacle_pos_y[i] && lucy_y + LUCY_H + velocityY > obstacle_pos_y[i] + obstacle_size_y[i]) begin
                    if(velocityX > 0 && lucy_x + (LUCY_W) <= obstacle_pos_x[i] && lucy_x + velocityX + (LUCY_W) >= obstacle_pos_x[i]) begin
                        next_velocityX = -velocityX;
                    end
                    else if(velocityX < 0 && lucy_x >= obstacle_pos_x[i] + obstacle_size_x[i] && lucy_x + velocityX < obstacle_pos_x[i] + obstacle_size_x[i]) begin
                        next_velocityX = -velocityX;
                    end
                end
            end
        end
        else begin
            if(jumpValue >= 21) begin //  (x + 1) / 2
                if(key_down[KEY_CODES[1]]) begin
                    next_velocityX = -3; 
                end
                else if(key_down[KEY_CODES[3]]) begin
                    next_velocityX = 3;
                end
                else begin
                    next_velocityX = 0;
                end
            end
            else if(key_down[KEY_CODES[0]]) begin
                next_velocityX = 0;
            end
            else if(jumpValue > 0) begin // key_valid broken??
                if(delay_keyDownA || key_down[KEY_CODES[1]]) begin
                    next_velocityX = -3; 
                end
                else if(delay_keyDownD || key_down[KEY_CODES[3]]) begin
                    next_velocityX = 3;
                end
                else begin
                    next_velocityX = 0;
                end
            end
            else begin
                if(delay_jumpValue) begin
                //if(velocityX == -2 || velocityX == 2) begin // delay_isGrounded 
                    next_velocityX = velocityX;
                end
                else if(key_down[KEY_CODES[1]]) begin
                    next_velocityX = -1; 
                end
                else if(key_down[KEY_CODES[3]]) begin
                    next_velocityX = 1;
                end
                else begin
                    next_velocityX = 0;
                end
            end
        end
    end
    else
        next_velocityX = 0;
end

// jump value
always @* begin
    if (state == GAME)
        begin
        if(key_down[KEY_CODES[0]] && isGrounded) begin
            next_jumpValue = jumpValue + 1;
        end
        else begin
            next_jumpValue = 0;
        end
    end
    else
        next_jumpValue = 0;
end

// is grounded
always @* begin
    isGrounded = 0;
    for(i=0; i<obstacle_n; i=i+1) begin
        if(lucy_y + LUCY_H == obstacle_pos_y[i]) begin
            // lucy_x ~ lucy_x + LUCY_W - 1
            // obstacle_pos_x ~ obstacle_pos_x + obstalce_size_x - 1
            if(lucy_x >= obstacle_pos_x[i] && lucy_x < obstacle_pos_x[i] + obstacle_size_x[i] ||
               lucy_x + LUCY_W > obstacle_pos_x[i] && lucy_x + LUCY_W <= obstacle_pos_x[i] + obstacle_size_x[i] ||
               lucy_x < obstacle_pos_x[i] && lucy_x + LUCY_W > obstacle_pos_x[i] + obstacle_size_x[i]) begin
                isGrounded = 1;
            end
        end
    end
end

always @* begin
    if (state == GAME)
    begin
        next_level = level;
        if(lucy_y < 240) begin
            next_level = LEVEL_2;
        end
        else if(lucy_y < 480) begin
            next_level = LEVEL_1;
        end
        else if(lucy_y < 720) begin
            next_level = LEVEL_0;
        end
    end
    else if (state == INIT)
        next_level = LEVEL_0;
    else
        next_level = level; 
end

always @* begin
    case(level)
        LEVEL_2 : begin
            offset_y = 0;
        end
        LEVEL_1 : begin
            offset_y = 240;
        end
        LEVEL_0 : begin
            offset_y = 480;
        end
    endcase
end

// to show the pictran of lucy
reg [3:0] row, col;
reg [3:0] search;
reg [0:47] lucy_animation;
reg [3:0] r_move, next_r_move, l_move, next_l_move;
reg face, next_face; // 0 for right, 1 for left
parameter FACE_R = 0;
parameter FACE_L = 1;
reg [6:0] end_move, next_end_move;

always @(posedge clk, posedge rst)
begin
    if (rst)
        face <= FACE_R;
    else
        face <= next_face;
end

always @*
begin
    if (state == GAME)
    begin
        if (isGrounded)
        begin
            if (last_change == KEY_CODES[1])
                next_face = FACE_L;
            else if (last_change == KEY_CODES[3])
                next_face = FACE_R;
            else
                next_face = face;
        end
        else
            next_face = face;
    end
    else
        next_face = face;
end

always @(posedge clk, posedge rst)
begin
    if (rst)
        r_move <= 0;
    else
        r_move <= next_r_move;
end

always @*
begin
    if (state == GAME)
    begin
        if (r_move == 4'd9)
            next_r_move = 0;
        else if (key_down[KEY_CODES[3]])
            next_r_move = r_move + 1;
        else
            next_r_move = 0;
    end
    else
        next_r_move = 0;
end

always @(posedge clk, posedge rst)
begin
    if (rst)
        l_move <= 0;
    else
        l_move <= next_l_move;
end

always @*
begin
    if (state == GAME)
    begin
        if (l_move == 4'd9)
            next_l_move = 0;
        else if (key_down[KEY_CODES[1]])
            next_l_move = l_move + 1;
        else
            next_l_move = 0;
    end
    else
        next_l_move = 0;
end

always @(posedge clk, posedge rst)
begin
    if (rst)
        end_move <= 0;
    else
        end_move <= next_end_move;
end

always @*
begin
    if (end_move == 7'd23)
        next_end_move = 0;
    else
        next_end_move = end_move + 1;
end

always @*
begin
    if (state == GAME)
    begin
        if (isGrounded)
        begin
            if (key_down[KEY_CODES[0]])
            begin
                search = 4'd8;
            end
            else if (key_down[KEY_CODES[3]])
            begin
                if (0 <= r_move && r_move <= 4'd2)
                    search = 4'd1;
                else if (4'd3 <= r_move && r_move <= 4'd5)
                    search = 4'd2;
                else if (4'd6 <= r_move && r_move <= 4'd8)
                    search = 4'd3;
            end
            else if (key_down[KEY_CODES[1]])
            begin
                if (0 <= l_move && l_move <= 4'd2)
                    search = 4'd5;
                else if (4'd3 <= l_move && l_move <= 4'd5)
                    search = 4'd6;
                else if (4'd6 <= l_move && l_move <= 4'd8)
                    search = 4'd7;
            end
            else
            begin
                if (face == FACE_R)
                    search = 4'd0;
                else
                    search = 4'd4;
            end
        end
        else
        begin
            if (velocityY > 0)
            begin
                if (velocityX > 0)
                    search = 4'd10;
                else if (velocityX < 0)
                    search = 4'd12;
                else
                    if (face == FACE_R)
                        search = 4'd10;
                    else
                        search = 4'd12;
            end
            else if (velocityY < 0)
            begin
                if (velocityX > 0)
                    search = 4'd9;
                else if (velocityX < 0)
                    search = 4'd11;
                else
                    if (face == FACE_R)
                        search = 4'd9;
                    else
                        search = 4'd11;
            end
        end
    end
    else if (state == END)
    begin
        if (7'd0 <= end_move && end_move <= 7'd5)
            search = 4'd14;
        else if (7'd6 <= end_move && end_move <= 7'd11)
            search = 4'd5;
        else if (7'd12 <= end_move && end_move <= 7'd17)
            search = 4'd15;
        else
            search = 4'd0;
    end
    else
        search = 4'd0;
end

always @*
begin
    row = (search) / 4;
    col = (search) % 4;
end

always @*
begin
    lucy_pixel_addr = ((h_cnt) - (lucy_x << 1) - (MAP_INIT_X << 1) + 18 * col + 72 * ((v_cnt) + (offset_y << 1) - (lucy_y << 1) + 24 * row));
end

always @*
begin
    background_pixel_addr = ((h_cnt >> 1) - MAP_INIT_X + 160 * ((v_cnt >> 1) + offset_y));
end

always @*
begin
    init_title_pixel_addr = ((h_cnt >> 1) - MAP_INIT_X - 20 + 120 * ((v_cnt >> 1) - 60));
end

always @*
begin
    space_pixel_addr = (h_cnt >> 1) - MAP_INIT_X - 52 + 56 * ((v_cnt >> 1) - 170);
end

always @*
begin
    end_title_pixel_addr = ((h_cnt >> 1) - MAP_INIT_X - 30 + 100 * (v_cnt >> 1));
end

always @*
begin
    crown_pixel_addr = (h_cnt >> 1) - MAP_INIT_X - 112 + 1 + 7 * ((v_cnt >> 1) - 60);
end

always @*
begin
    restart_pixel_addr = (h_cnt >> 1) - MAP_INIT_X - 32 + 1 + 96 * ((v_cnt >> 1) - 170);
end

// print what
parameter PRINT_COLOR = 3'd0;
parameter PRINT_LUCY = 3'd1;
parameter PRINT_BACKGROUND = 3'd2;
parameter PRINT_INIT_TITLE = 3'd3;
parameter PRINT_END_TITLE = 3'd4;
parameter PRINT_SPACE = 3'd5;
parameter PRINT_CROWN = 3'd6;
parameter PRINT_RESTART = 3'd7;

reg [5:0] space_cnt, next_space_cnt;
reg [5:0] restart_cnt, next_restart_cnt;

always @(posedge clk, posedge rst)
begin
    if (rst)
        space_cnt <= 0;
    else
        space_cnt <= next_space_cnt;
end

always @*
begin
    if (state == INIT)
    begin
        if (space_cnt == 6'd21)
            next_space_cnt = 0;
        else
            next_space_cnt = space_cnt + 1;
    end
    else
        next_space_cnt = 0;
end

always @(posedge clk, posedge rst)
begin
    if (rst)
        restart_cnt <= 0;
    else
        restart_cnt <= next_restart_cnt;
end

always @*
begin
    if (state == END)
    begin
        if (restart_cnt == 6'd21)
            next_restart_cnt = 0;
        else
            next_restart_cnt = restart_cnt + 1;
    end
    else
        next_restart_cnt = 0;
end

always @* begin
    if (state == GAME)
    begin
        if ((h_cnt>>1) >= MAP_INIT_X && (h_cnt>>1) < MAP_INIT_X + MAP_W) begin
            if (offset_y + (v_cnt>>1) >= lucy_y && offset_y + (v_cnt>>1) < lucy_y + LUCY_H && 
               (h_cnt>>1) > lucy_x + MAP_INIT_X && (h_cnt>>1) <= lucy_x + LUCY_W + MAP_INIT_X) begin
                print_what = PRINT_LUCY;
            end
            else if (level == LEVEL_2 && (h_cnt >> 1) >= MAP_INIT_X + 112 && (h_cnt >> 1) < MAP_INIT_X + MAP_W - 41 &&
                     (v_cnt >> 1) >= 60 && (v_cnt >> 1) <= 68)
                print_what = PRINT_CROWN;
            else begin
                print_what = PRINT_BACKGROUND;
            end
        end
        else begin
            print_what = PRINT_COLOR;
        end
    end
    else if (state == INIT)
    begin
        if((h_cnt>>1) >= MAP_INIT_X && (h_cnt>>1) < MAP_INIT_X + MAP_W) begin
            if(offset_y + (v_cnt>>1) >= lucy_y && offset_y + (v_cnt>>1) < lucy_y + LUCY_H && 
               (h_cnt>>1) > lucy_x + MAP_INIT_X && (h_cnt>>1) <= lucy_x + LUCY_W + MAP_INIT_X) begin
                print_what = PRINT_LUCY;
            end
            else if ((h_cnt >> 1) >= MAP_INIT_X + 20 && (h_cnt >> 1) <= MAP_INIT_X + MAP_W - 20 && 
                     (v_cnt >> 1) >= 60 &&  (v_cnt >> 1) < 90)
            begin
                print_what = PRINT_INIT_TITLE;
            end
            else if ((h_cnt >> 1) >= MAP_INIT_X + 52 && (h_cnt >> 1) <= MAP_INIT_X + MAP_W - 52 &&
                     (v_cnt >> 1) >= 170 &&  (v_cnt >> 1) < 180)
            begin
                if (0 <= space_cnt && space_cnt <= 6'd10)
                    print_what = PRINT_SPACE;
                else
                    print_what = PRINT_BACKGROUND;
            end
            else begin
                print_what = PRINT_BACKGROUND;
            end
        end
        else begin
            print_what = PRINT_COLOR;
        end
    end
    else if (state == END)
    begin
        if((h_cnt>>1) >= MAP_INIT_X && (h_cnt>>1) < MAP_INIT_X + MAP_W) begin
            if(offset_y + (v_cnt>>1) >= lucy_y && offset_y + (v_cnt>>1) < lucy_y + LUCY_H && 
               (h_cnt>>1) > lucy_x + MAP_INIT_X && (h_cnt>>1) <= lucy_x + LUCY_W + MAP_INIT_X) begin
                print_what = PRINT_LUCY;
            end
            else if ((h_cnt >> 1) >= MAP_INIT_X + 32 && (h_cnt >> 1) <= MAP_INIT_X + MAP_W - 32 && 
                     (v_cnt >> 1) >= 170 &&  (v_cnt >> 1) < 180)
            begin
                if (0 <= restart_cnt && restart_cnt <= 6'd10)
                    print_what = PRINT_RESTART;
                else
                    print_what = PRINT_BACKGROUND;
            end
            else begin
                print_what = PRINT_BACKGROUND;
            end
        end
        else begin
            print_what = PRINT_COLOR;
        end
    end
end

always @* begin
    if((h_cnt>>1) >= MAP_INIT_X && (h_cnt>>1) < MAP_INIT_X + MAP_W) begin
        if(offset_y + (v_cnt>>1) >= lucy_y && offset_y + (v_cnt>>1) < lucy_y + LUCY_H && 
           (h_cnt>>1) >= lucy_x + MAP_INIT_X && (h_cnt>>1) < lucy_x + LUCY_W + MAP_INIT_X) begin
            pixel = 12'hA2F;
        end
        else begin
            pixel = 12'hFFF;
            for(i=0; i<obstacle_n; i=i+1) begin
                if(offset_y + (v_cnt>>1) >= obstacle_pos_y[i] && offset_y + (v_cnt>>1) < obstacle_pos_y[i] + obstacle_size_y[i] && 
                   (h_cnt>>1) >= obstacle_pos_x[i] + MAP_INIT_X && (h_cnt>>1) < obstacle_pos_x[i] + obstacle_size_x[i] + MAP_INIT_X) begin
                    pixel = 12'h0F0;
                end
            end
        end
    end
    else begin
        pixel = 12'h0;
    end
end

endmodule
