/*UART adder demo-subcircuit*/
/* This module adds RX[67:64]+RX[3:0]. This is just for demonstration that you are sending correct 
data to the FPGA since data sent from the computer is in ASCII format, subtraction -48 from half should give you real number instead of ascii
If you really want arithematic operation you need to design a small ascii to hex circuit/
//Jubayer, 10/29/2018,Auburn
*/

`timescale 1ns / 1ps

module adder(

input clk,
input rst,
input [127:0]Din,
input Din_valid,
output reg [127:0]Dout,
output  Dout_valid

);

reg [8:0] shift;

assign Dout_valid = shift[8];

always @(posedge clk, posedge rst) begin
	if (rst) begin
		shift <= 9'b000000000;
	end
	else begin
		shift <= shift << 1;// wait few cycles
		shift[0] <= Din_valid;
		Dout[3:0]<=(Din[67:64]-48)+(Din[3:0]-48);// -48 makes them number instead of Ascii. 
		Dout[127:4]<=0;// pad the MSB`s with zeros. 
	end
end

endmodule
