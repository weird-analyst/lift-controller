`timescale 1ns / 1ps

// uncomment below line for simulation
module LiftController(DirectionUp, DirectionDown, Floors,NextFloor,NextStopDirection, s_clk, reset);

// uncomment below line for implementation
//module LiftController(DirectionUp, DirectionDown, Floors,NextFloor,NextStopDirection, clk, reset, an, dp, a_to_g, cout);
    input [3:0] DirectionUp; //single bit input from each floor.1 means uprequest, 0 means no request for up direction
    input [3:0] DirectionDown; //single bit input from each floor.1 means request for going down, 0 means no request for going down
    input [4:0]Floors; //[fl4, fl3, fl2, fl1, fl0]  request for floor 4, 3, 2, 1 respectively.
    input reset; 

// uncomment below line for simulation
     input s_clk;

// uncomment below line for implementation
//    input clk;

    output reg [1:0] NextStopDirection = 2'b00; //The lift will move in up/down direction in next clock; 10means up, 01means downand 00 implies it will stay in the current floor and 11 is invalid. 
    output reg[2:0]NextFloor; //next stop of the liftend module

// comment below line for simulation    
//    // For BCD Display
//    output reg cout;     
//    // For 7 segment display output of current floor
//    output wire [6:0] a_to_g;
//    output wire [7:0] an;
//    output wire dp;
//    assign dp = 1;
//    assign an = 8'b11111110;
// till here

    // Declaring State Encodings
    // Cooresponding to each floor we have an idle state, moving up, moving down state
    // and cooresponding to all transitions between two floors we have a state

    parameter S0_idle=5'b00000;
    parameter S1_idle=5'b00001;
    parameter S2_idle=5'b00010;
    parameter S3_idle=5'b00011;
    parameter S4_idle=5'b00100;
    parameter S1_up=5'b00110;
    parameter S2_up=5'b00111;
    parameter S3_up=5'b01000;
    parameter S1_down=5'b01001;
    parameter S2_down=5'b01010;
    parameter S3_down=5'b01011;
    parameter M01=5'b01101;
    parameter M12=5'b01110;
    parameter M23=5'b01111;
    parameter M34=5'b10000;
    parameter M43=5'b10001;
    parameter M32=5'b10010;
    parameter M21=5'b10011;
    parameter M10=5'b10100;

    // Registers for maintainig current state (cstate), i to maitain count upto 4 cycles in moving states
    // up, down, f to track and store all requests
    reg[4:0] cstate;
    reg[2:0] i = 0;
    reg [3:0] up = 4'b0000;   //3210
    reg [3:0] down = 4'b0000; //4321
    reg [4:0] f = 5'b00000;
    reg [2:0] temp = 3'b111;
    reg [2:0] cfloor;


// comment below for simulation    
//    // Converting Input clock at 10MHz to Slow Clock (s_clk) using a counter of 24 bits
//    reg [24:0]cnt = 0; 
//    reg s_clk = 0;

//    always @(posedge clk) begin
//        cnt = cnt + 1;
//        if(cnt == 25'b1111111111111111111111111) begin
//            cnt=0;
//            s_clk = ~s_clk;
//        end
//    end


//    // Instantiating 7 segment display to show cfloor output
//    seg7decimal D1(.x(cfloor), .a_to_g(a_to_g));

////     Assigning clock output
//    always @(*) cout = s_clk;
// till here
    
    always @(posedge s_clk) begin
        // If you are in some stopping state you need to clear the stored values in the up, down and f array signifying you have cleared the cooresponding requests
        if(cstate == S0_idle)begin
            cfloor = 0;
            up[0]=0;
            f[0]=0;
        end
        else if(cstate == S1_down ||cstate == S1_up ||cstate == S1_idle)begin
            cfloor = 1;
            up[1]=0;
            down[0]=0;
            f[1]=0;
        end
        else if(cstate == S2_down ||cstate == S2_up ||cstate == S2_idle)begin
            cfloor = 2;
            up[2]=0;
            down[1]=0;
            f[2]=0;
        end
        else if(cstate == S3_down ||cstate == S3_up ||cstate == S3_idle)begin
            cfloor = 3;
            up[3]=0;
            down[2]=0;
            f[3]=0;
        end
        else if(cstate == S4_idle)begin
            cfloor = 4;
            down[3]=0;
            f[4]=0;
        end
    
        up = DirectionUp|up;
        down = DirectionDown|down;
        f = Floors|f;

        // If reset is on clear all pending requests and stop at 0 
        if (reset) begin
            up = 0;
            down = 0;
            f = 0; 
            cstate = S0_idle; 
            NextFloor = 0;
            NextStopDirection = 0;
        end
        else begin
            // Cases based on state
            case (cstate)
                // In S0_idle if requests are only from 0th floor or no requests at all, stop there (specified by if condition)
                // If there is some request based on order specified change cstate and NextFloor value.
                S0_idle:begin
                    i = 0;
                    temp = 3'b111;
                    if((~(|up)&&~(|down)&&~(|f))||(up[0]||f[0])) begin
                        cstate = cstate;
                        NextStopDirection = 2'b00;
                        NextFloor = 0;
                    end
                    else begin
                        cstate = M01;
                        NextStopDirection = 2'b10;
                        if(f[1]) NextFloor = 1;
                        else if(f[2]) NextFloor = 2;
                        else if(f[3]) NextFloor = 3;
                        else if(f[4]) NextFloor = 4;
                        else if(~(|f)) begin
                            if(up[1]) NextFloor = 1;
                            else if(down[0]) NextFloor = 1;
                            else if(up[2]) NextFloor = 2;
                            else if(down[1]) NextFloor = 2;
                            else if(up[3]) NextFloor = 3;
                            else if(down[2]) NextFloor = 3;
                            else if(down[3]) NextFloor = 4;
                        end
                    end
                end
                // In S1_idle --> S4_idle, check first if only requests from 1st floor or no other requests, stop at that floor
                // or in other case based on which floor the request has come from (priority ordered) or which floor the request has come from
                // change nextfloor and next stop direction and go into the cooresponding moving state.
                S1_idle:begin
                    i = 0;
                    temp = 3'b111;
                    if((~(|up)&&~(|down)&&~(|f))||(up[1]||f[1]||down[0])) begin
                        cstate = cstate;
                        NextStopDirection = 2'b00;
                        NextFloor = 1;
                    end
                    else if(f[0]) begin
                        cstate = M10;
                        NextStopDirection = 1;
                        NextFloor = 0;
                    end
                    else if(f[2]) begin
                        cstate = M12;
                        NextStopDirection = 2;
                        NextFloor = 2;
                    end
                    else if(f[3]) begin
                        cstate = M12;
                        NextStopDirection = 2;
                        NextFloor = 3;
                    end
                    else if(f[4]) begin
                        cstate = M12;
                        NextStopDirection = 2;
                        NextFloor = 4;
                    end
                    else if(up[0])begin
                        cstate = M10;
                        NextStopDirection = 1;
                        NextFloor = 0;
                    end
                    else if(up[2] || down[1])begin
                        cstate = M12;
                        NextStopDirection = 2;
                        NextFloor = 2;
                    end
                    else if(up[3] || down[2])begin
                        cstate = M12;
                        NextStopDirection = 2;
                        NextFloor = 3;
                    end
                    else if(down[3])begin
                        cstate = M12;
                        NextStopDirection = 2;
                        NextFloor = 4;
                    end
                end
                S2_idle:begin
                    i = 0;
                    temp = 3'b111;
                    if((~(|up)&&~(|down)&&~(|f))||(up[2]||f[2]||down[1])) begin
                        cstate = cstate;
                        NextStopDirection = 2'b00;
                        NextFloor = 2;
                    end
                    else if(f[0]) begin
                        cstate = M21;
                        NextStopDirection = 1;
                        NextFloor = 0;
                    end
                    else if(f[1]) begin
                        cstate = M21;
                        NextStopDirection = 1;
                        NextFloor = 1;
                    end
                    else if(f[3]) begin
                        cstate = M23;
                        NextStopDirection = 2;
                        NextFloor = 3;
                    end
                    else if(f[4]) begin
                        cstate = M23;
                        NextStopDirection = 2;
                        NextFloor = 4;
                    end
                    else if(up[0])begin
                        cstate = M21;
                        NextStopDirection = 1;
                        NextFloor = 0;
                    end
                    else if(up[1] || down[0])begin
                        cstate = M21;
                        NextStopDirection = 1;
                        NextFloor = 1;
                    end
                    else if(up[3] || down[2])begin
                        cstate = M23;
                        NextStopDirection = 2;
                        NextFloor = 3;
                    end
                    else if(down[3])begin
                        cstate = M23;
                        NextStopDirection = 2;
                        NextFloor = 4;
                    end
                end
                S3_idle:begin
                    i = 0;
                    temp = 3'b111;
                    if((~(|up)&&~(|down)&&~(|f))||(up[3]||f[3]||down[2])) begin
                        cstate = cstate;
                        NextStopDirection = 2'b00;
                        NextFloor = 3;
                    end
                    else if(f[4]) begin
                        cstate = M34;
                        NextStopDirection = 2;
                        NextFloor = 4;
                    end
                    else if(f[2]) begin
                        cstate = M32;
                        NextStopDirection = 1;
                        NextFloor = 2;
                    end
                    else if(f[1]) begin
                        cstate = M32;
                        NextStopDirection = 1;
                        NextFloor = 1;
                    end
                    else if(f[0]) begin
                        cstate = M32;
                        NextStopDirection = 1;
                        NextFloor = 0;
                    end
                    else if(down[3])begin
                        cstate = M34;
                        NextStopDirection = 2;
                        NextFloor = 4;
                    end
                    else if(up[2] || down[1])begin
                        cstate = M32;
                        NextStopDirection = 1;
                        NextFloor = 2;
                    end
                    else if(up[1] || down[0])begin
                        cstate = M32;
                        NextStopDirection = 1;
                        NextFloor = 1;
                    end
                    else if(up[0])begin
                        cstate = M32;
                        NextStopDirection = 1;
                        NextFloor = 0;
                    end
                end
                S4_idle:begin
                    i = 0;
                    temp = 3'b111;
                    if((~(|up)&&~(|down)&&~(|f))||(f[4]||down[3])) begin
                        cstate = cstate;
                        NextStopDirection = 2'b00;
                        NextFloor = 4;
                    end
                    else if(f[3]) begin
                        cstate = M43;
                        NextStopDirection = 1;
                        NextFloor = 3;
                    end
                    else if(f[2]) begin
                        cstate = M43;
                        NextStopDirection = 1;
                        NextFloor = 2;
                    end
                    else if(f[1]) begin
                        cstate = M43;
                        NextStopDirection = 1;
                        NextFloor = 1;
                    end
                    else if(f[0]) begin
                        cstate = M43;
                        NextStopDirection = 1;
                        NextFloor = 0;
                    end
                    else if(up[3] || down[2])begin
                        cstate = M43;
                        NextStopDirection = 1;
                        NextFloor = 3;
                    end
                    else if(up[2] || down[1])begin
                        cstate = M43;
                        NextStopDirection = 1;
                        NextFloor = 2;
                    end
                    else if(up[1] || down[0])begin
                        cstate = M43;
                        NextStopDirection = 1;
                        NextFloor = 1;
                    end
                    else if(up[0])begin
                        cstate = M43;
                        NextStopDirection = 1;
                        NextFloor = 0;
                    end
                end
                // Si_up signifies that the lift was actually moving to some higher floor from below but a request came in the middle to go up or stop at i
                // if request persists from i keep stopping there otherwise get the actual next floor (stored in temp) and start moving up
                // Similarly Si_down signifies the lift stopped to take request for going down from one of the middle floors and is stopped there till request persists
                // otherwise it starts moving the down direction
                S1_up: begin
                    i = 0;
                    if(f[1]||up[1]||down[0]) begin
                        cstate = S1_up;
                        NextStopDirection = 2'b00;
                    end
                    else begin
                        cstate = M12;
                        NextFloor = temp;
                        temp = 7;
                        NextStopDirection = 2'b10;
                    end
                end
                S1_down: begin
                    i = 0;
                    if(f[1]||up[1]||down[0])begin
                        cstate = S1_down;
                        NextStopDirection = 2'b00;
                    end
                    else begin
                        cstate = M10;
                        NextFloor = temp;
                        temp = 7;
                        NextStopDirection = 2'b01;
                    end
                end 
                S2_up: begin
                    i = 0;
                    if(f[2]||up[2]||down[1]) begin
                        cstate = S2_up;
                        NextStopDirection = 2'b00;
                    end
                    else begin
                        cstate = M23;
                        NextFloor = temp;
                        temp = 7;
                        NextStopDirection = 2'b10;
                    end
                end
                S2_down: begin
                    i = 0;
                    if(f[2]||up[2]||down[1]) begin
                        cstate = S2_down;
                        NextStopDirection = 2'b00;
                    end
                    else begin
                        cstate = M21;
                        NextFloor = temp;
                        temp = 7;
                        NextStopDirection = 2'b01;
                    end
                end
                S3_up: begin
                    i = 0;
                    if(f[3]||up[3]||down[2]) begin
                        cstate = S3_up;
                        NextStopDirection = 2'b00;
                    end
                    else begin
                        cstate = M34;
                        NextFloor = temp;
                        temp = 7;
                        NextStopDirection = 2'b10;
                    end
                end
                S3_down: begin
                    i=0;
                    if(f[3]||up[3]||down[2]) begin
                        cstate = S3_down;
                        NextStopDirection = 2'b00;
                    end
                    else begin
                        cstate = M32;
                        NextFloor = temp;
                        temp = 7;
                        NextStopDirection = 2'b01;
                    end
                end
                // M_i_i+1 state signifies the lift is moving from i to i+1
                // it also checks for requests for going up or stopping at i+1 if i+1 was not it's initial target floor
                // if such a case happens it stores the actual target floor in temp 
                // at the 4th cycle it checks if temp is changed it goes to S_i+1_up otherwise proceeds to M_i+1_i+2
                M01: begin
                    i = i + 1;
                    cfloor = 0;
                    if(i < 4) begin
                        cstate = M01;
                        NextStopDirection = 2'b10;
                        if((NextFloor==2||NextFloor==3||NextFloor==4) && (up[1]||f[1]))
                            begin
                                temp = NextFloor;
                                NextFloor = 1;
                            end
                    end
                    else begin
                        if(NextFloor==1 && temp!=7)
                            cstate = S1_up;
                        else if(NextFloor==1 && temp==7)
                            cstate = S1_idle;
                        else
                            begin
                                i=0;
                                cstate = M12;
                                NextStopDirection = 2'b10;
                            end
                    end
                end  
                M12: begin
                    i = i + 1;
                    cfloor = 1;
                    if(i < 4) begin
                        cstate = M12;
                        NextStopDirection = 2'b10;
                        if((NextFloor==3||NextFloor==4) && (up[2]||f[2]))
                            begin
                                temp = NextFloor;
                                NextFloor = 2;
                            end
                    end
                    else begin
                        if(NextFloor==2 && temp!=7)
                            cstate = S2_up;
                        else if(NextFloor==2 && temp==7)
                            cstate = S2_idle;
                        else
                            begin
                                i=0;
                                cstate = M23;
                                NextStopDirection = 2'b10;
                            end
                    end
                end
                M23: begin
                    i = i + 1;
                    cfloor = 2;
                    if(i < 4) begin
                        cstate = M23;
                        NextStopDirection = 2'b10;
                        if((NextFloor==4) && (up[3]||f[3]))
                            begin
                                temp = NextFloor;
                                NextFloor = 3;
                            end
                    end
                    else begin
                        if(NextFloor==3 && temp!=7)
                            cstate = S3_up;
                        else if(NextFloor==3 && temp==7)
                            cstate = S3_idle;
                        else
                            begin
                                i=0;
                                cstate = M34;
                                NextStopDirection = 2'b10;
                            end
                    end
                end
                M34: begin
                    i = i + 1;
                    cfloor = 3;
                    if(i < 4) begin
                        cstate = M34;
                        NextStopDirection = 2'b10;
                    end
                    else begin
                        i=0;
                        cstate = S4_idle;
                        NextStopDirection = 2'b00;
                    end
                end   
                // M_i_i-1 signifies that the lift is moving from floor i to i-1
                // it also checks for requests for going down or stopping at i-1 if i-1 was not it's initial target floor
                // if such a case happens it stores the actual target floor in temp 
                // at the 4th cycle it checks if temp is changed it goes to S_i-1_down otherwise proceeds to M_i-1_i-2
                M43:begin
                    i = i + 1;
                    cfloor = 4;
                    if(i < 4) begin
                        cstate = M43;
                        NextStopDirection = 2'b01;
                        if((NextFloor==2||NextFloor==1||NextFloor==0) && (down[2]||f[3]))
                            begin
                                temp = NextFloor;
                                NextFloor = 3;
                            end
                    end
                    else begin
                        if(NextFloor==3 && temp!=7)
                            cstate = S3_down;
                        else if(NextFloor==3 && temp==7)
                            cstate = S3_idle;
                        else begin
                            i=0;
                            cstate = M32;
                            NextStopDirection = 2'b01;
                        end
                    end
                end
                M32:begin
                    i = i + 1;
                    cfloor = 3;
                    if(i < 4) begin
                        cstate = M32;
                        NextStopDirection = 2'b01;
                        if((NextFloor==1||NextFloor==0) && (down[1]||f[2]))
                            begin
                                temp = NextFloor;
                                NextFloor = 2;
                            end
                    end
                    else begin
                        if(NextFloor==2 && temp!=7)
                            cstate = S2_down;
                        else if(NextFloor==2 && temp==7)
                            cstate = S2_idle;
                        else begin
                            i=0;
                            cstate = M21;
                            NextStopDirection = 2'b01;
                        end
                    end
                end
                M21:begin
                    i = i + 1;
                    cfloor = 2;
                    if(i < 4) begin
                        cstate = M21;
                        NextStopDirection = 2'b01;
                        if((NextFloor==0) && (down[0]||f[1]))
                            begin
                                temp = NextFloor;
                                NextFloor = 1;
                            end
                    end
                    else begin
                        if(NextFloor==1 && temp!=7)
                            cstate = S1_down;
                        else if(NextFloor==1 && temp==7)
                            cstate = S1_idle;
                        else begin
                            i=0;
                            cstate = M10;
                            NextStopDirection = 2'b01;
                        end
                    end
                end
                M10:begin
                    i = i + 1;
                    cfloor = 1;
                    if(i < 4) begin
                        cstate = M10;
                        NextStopDirection = 2'b01;
                    end
                    else begin
                        cstate = S0_idle;
                    end
                end   
            endcase
        end
    end
endmodule

// Seven segment display module for currentFloor
module seg7decimal(input [2:0] x,output reg [6:0] a_to_g);
	always @(*)
        case(x)
            0:a_to_g = 7'b0000001;////0000										
            1:a_to_g = 7'b1001111;////0001			
            2:a_to_g = 7'b0010010;////0010												
            3:a_to_g = 7'b0000110;////0011										
            4:a_to_g = 7'b1001100;////0100												          
            default: a_to_g = 7'b0000000; // U 
        endcase
endmodule


