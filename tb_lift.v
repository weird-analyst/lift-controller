`timescale 1ns / 1ps


module tb_lift();
    reg [3:0] DirectionUp = 0; //single bit input from each floor.1 means uprequest, 0 means no request for up direction (3,2,1,0)
    reg [3:0] DirectionDown = 0; //single bit input from each floor.1 means request for going down, 0 means no request for going down (4,3,2,1)
    reg [4:0]Floors = 0; //[fl4, fl3, fl2, fl1, fl0]  request for floor 4, 3, 2, 1 respectively.
    reg reset; 
    reg clk = 0;
    wire [1:0] NextStopDirection; //The lift will move in up/down direction in next clock; 10means up, 01means downand 00 implies it will stay in the current floor and 11 is invalid. 
    wire [2:0]NextFloor; //next stop of the liftend module

    LiftController uut (DirectionUp, DirectionDown, Floors,NextFloor,NextStopDirection, clk, reset);

    always begin
        #0.5 clk = ~clk;
    end

    initial begin
        reset = 1;
        #5;
        reset = 0;
        

        #1        
        DirectionUp = 4'b0100;

        #2        
        DirectionDown = 4'b1000;
        
        #5
        DirectionUp = 4'b0000;
        Floors = 5'b01000;
        
        #4
        Floors = 5'b00000;
        
        #4
        DirectionDown = 4'b0000;
        Floors = 5'b00100;
                
        #8
        Floors = 5'b00000;

        #2
        DirectionUp = 4'b1000;
        DirectionDown = 4'b0001;

        #4
        DirectionDown = 4'b0000;
        Floors = 5'b00001;
        
        #4
        Floors = 5'b00000;
        
        #2
        DirectionUp = 4'b1100;
    
        #6
        DirectionUp = 4'b1000;
        Floors = 5'b01000;
        
        #4
        DirectionUp = 4'b0000;
        Floors = 5'b10000;
        
        #4
        Floors = 5'b00000;
        
        #2
        Floors = 5'b00100;
        
        #2
        DirectionUp = 4'b0001;
        
        #6
        Floors = 5'b00000;
        
        #4
        DirectionUp = 4'b0000;
        Floors = 5'b10000;
        
        #100 $finish;
    end        

initial begin
    $monitor("Time = %0t DirectionUp = %b DirectionDown = %b Floors = %b NextFloor = %b NextStopDirection = %b",$time,DirectionUp,DirectionDown,Floors,NextFloor,NextStopDirection);
end

endmodule
