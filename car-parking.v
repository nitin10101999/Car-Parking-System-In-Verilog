`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.11.2018 23:03:02
// Design Name: 
// Module Name: car-parking
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//module bcd2bin_direct
//   (
//    input [3:0] bcd1, bcd0,
//    output [6:0] bin
//   );
//   assign bin = (bcd1 * 4'b1010) + {3'b0, bcd0};
//endmodule


module car_parking(
    input clk, 
//    input clr,
    input BNTL,
    input BNTC,
    input BNTR,
    input BNTD,
    input [15:0] Pin,
    output reg [6:0] empty_slots,
    output reg [3:0] Anode_Activate,
    output reg [6:0] LED_out,
    output wire dp
    );
    reg [26:0] one_second_counter; // counter for generating 1 second clock enable
    reg [15:0] seconds;
    reg [6:0] password;
    reg [6:0] show_password;
    reg [3:0] LED_BCD;
    wire [1:0] LED_activating_counter;
    reg [19:0] refresh_counter;
    reg [6:0] token;
    reg [6:0] pin_array [0:99];
    reg [15:0] seconds_array [0:99];
    reg check;
    reg check_password;
    reg [6:0] ind;
    reg [6:0] pass;
    integer i,j,check_free [0:99];
    reg [15:0] price;
    reg[1:0]l;
    reg [6:0]range;
    reg [2:0] on_7_seg;
    
    initial
    begin 
        range=40;
        token = 0;
        password = 0;
        show_password = 0;
        check = 0;
        one_second_counter=0;
        seconds=0;
        empty_slots=99;
        for(i=0; i<100; i=i+1) begin
        	check_free[i] = 1;
        end;
    end
    
    always @(posedge clk)
    if(BNTL && empty_slots>0)
     l=0;
    else if(BNTR)
     l=1;
     
    always @(posedge clk)
    begin
    if(BNTL && empty_slots>0)
     on_7_seg=0;
    else if(BNTR)
     on_7_seg=0;
    else if(one_second_counter >=99999999 && on_7_seg <5)
     on_7_seg = on_7_seg + 1;
    end
     
    
     
    always @(posedge clk)
    begin
        if(one_second_counter>=99999999)
        begin 
             one_second_counter <= 0;
             seconds <= seconds + 1;
        end
        else
            one_second_counter <= one_second_counter + 1;
    end 
    
    always @(posedge clk)
    if(BNTL && check==0 && empty_slots>0)
    begin
        for(j=1; check_free[j] !=1 && j<100; j=j+1) begin
            token=j;
        end
        token = j;
        check_free[token] = 0;
        #5 check = 1;
        show_password=password;
        pin_array[token] = password;
        seconds_array[token] = seconds;
        empty_slots = empty_slots - 1;
    end
    else if (BNTD)
        check=0;
    else if(BNTR)
    begin
        //bcd2bin_direct(Pin[7:4],Pin[3:0],ind);
        ind = (Pin[11:8] * 4'b1010) + {3'b0, Pin[3:0]};
        pass = (Pin[15:12] * 4'b1010) + {3'b0, Pin[7:4]};
        //bcd2bin_direct(Pin[15:12],Pin[11:8],pass);
        if(pin_array[ind] == pass && check_free[ind] !=1) begin
            empty_slots = empty_slots + 1;
            price = seconds - seconds_array[ind];
            if(price>range)
            price=(price-range)*2+range;
            check_free[ind]=1;
        end
        else if(pin_array[ind] != pass )
            price = 0;
    end
    else if(BNTC)
    begin
        //range=40;
        token = 0;
        //password = 0;
        show_password = 0;
        check = 0;
        //one_second_counter=0;
        //seconds=0;
        empty_slots=99;
        for(i=0; i<100; i=i+1) begin
            check_free[i] = 1;
        end;
    end
          
    always @(posedge clk)
        begin
            if(password > 99)
                password=0;
            else
                password = password + 1;
        end
    
    always @(posedge clk or posedge BNTC)
        begin 
        if(BNTC)
            refresh_counter <= 0;
        else
            refresh_counter <= refresh_counter + 1;
        end

    assign LED_activating_counter = refresh_counter[19:18];
    always @(*)
    begin
        if(l==0 && on_7_seg<5)
        begin
            case(LED_activating_counter)
            2'b00: begin
                Anode_Activate = 4'b0111; 
                LED_BCD = show_password/10;
                  end
            2'b01: begin
                Anode_Activate = 4'b1101; 
                LED_BCD = (show_password % 10);
                  end
            2'b10: begin
                Anode_Activate = 4'b1011; 
                LED_BCD = token/10;
                    end
            2'b11: begin
                Anode_Activate = 4'b1110; 
                LED_BCD = (token % 10);
                   end
            endcase
        end
        else if(l==1 && on_7_seg<5)
        begin
            case(LED_activating_counter)
                2'b00: begin
                    Anode_Activate = 4'b0111; 
                    // activate LED1 and Deactivate LED2, LED3, LED4
                    LED_BCD = price/1000;
                      end
                2'b01: begin
                    Anode_Activate = 4'b1011; 
                    // activate LED2 and Deactivate LED1, LED3, LED4
                    LED_BCD = (price % 1000)/100;
                      end
                2'b10: begin
                    Anode_Activate = 4'b1101; 
                    // activate LED3 and Deactivate LED2, LED1, LED4
                    LED_BCD = ((price % 1000)%100)/10;
                        end
                2'b11: begin
                    Anode_Activate = 4'b1110; 
                    // activate LED4 and Deactivate LED2, LED3, LED1
                    LED_BCD = ((price % 1000)%100)%10;
                       end
            endcase
        end
        else
        begin
            Anode_Activate = 4'b1111;
        end
    end
    
    always @(*)
    begin
        case(LED_BCD)
        4'b0000: LED_out = 7'b0000001; // "0"     
        4'b0001: LED_out = 7'b1001111; // "1" 
        4'b0010: LED_out = 7'b0010010; // "2" 
        4'b0011: LED_out = 7'b0000110; // "3" 
        4'b0100: LED_out = 7'b1001100; // "4" 
        4'b0101: LED_out = 7'b0100100; // "5" 
        4'b0110: LED_out = 7'b0100000; // "6" 
        4'b0111: LED_out = 7'b0001111; // "7" 
        4'b1000: LED_out = 7'b0000000; // "8"     
        4'b1001: LED_out = 7'b0000100; // "9" 
        default: LED_out = 7'b0000001; // "0"
        endcase
    end
    
endmodule
