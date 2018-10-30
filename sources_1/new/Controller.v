
/* State controller for a UART demo
This module has a dependency on uart.v and adder.v. 
It  is designed to serve as a 
tutorial to hardware secusrity -I course fro UART  interfacing (FPGA and PC`s serial terminal). 
The data stream is 128 bit both ways (TX and RX). 

-Jubayer, 10/29/2018
-Aubrun University, ECE
*/
`timescale 1ns / 1ps

module Controller (clk, rst, uart_txd, uart_rxd);

input clk, rst;
input uart_rxd;
output uart_txd;

// State machine states
localparam IDLE = 2'b00, RECEIVING = 2'b01, TRANSMITTING = 2'b10;

// AES
reg [127:0] data_in;
wire [127:0] data_out;
reg input_data_valid;
wire output_data_valid;
reg [127:0] temp_out;

// UART
reg [7:0] uart_tx_data;
reg uart_tx_data_valid;
wire uart_tx_data_ack;
wire uart_txd, uart_rxd;
wire [7:0] uart_rx_data;
wire uart_rx_data_fresh;

// State machine
reg [1:0] state, next_state;
reg [4:0] uart_byte_counter;
/// Call UART IP
uart u (.clk(clk),
		.rst(rst),
		.tx_data(uart_tx_data),
		.tx_data_valid(uart_tx_data_valid),
		.tx_data_ack(uart_tx_data_ack),
		.txd(uart_txd),
		.rx_data(uart_rx_data),
		.rx_data_fresh(uart_rx_data_fresh),
		.rxd(uart_rxd));

//This are proabaly most sensitive parameters!
defparam u .CLK_HZ = 100_000_000;
defparam u .BAUD = 115200;
// call Mr. Adder
adder ADD1 (.clk(clk),
		 .rst(rst),
		 .Din_valid(input_data_valid),
		 .Dout_valid(output_data_valid),
		 .Din(data_in),
		 .Dout(data_out));

always @(posedge clk or posedge rst)
begin
	if (rst) begin// Send everything back to home 
		uart_byte_counter <= 5'b00000;
		state <= IDLE;
		next_state <= IDLE;
		uart_tx_data <= 8'h00;
		uart_tx_data_valid <= 1'b0;
		input_data_valid <= 1'b0;
	end
	else begin
		state = next_state;
		case(state)
			IDLE: begin/// wait and chill, this is deafult state for the FSM
				input_data_valid <= 1'b0;
				uart_byte_counter <= 5'b00000;
				if (uart_rx_data_fresh == 1'b1) begin
					next_state <= RECEIVING;
					
					data_in[7:0]<=uart_rx_data;
					uart_byte_counter <= 1;
				end
				else if (output_data_valid == 1'b1) begin
					next_state <= TRANSMITTING;
					temp_out <= data_out;
				end
				else begin
					next_state <= IDLE;
				end
			end
			RECEIVING: begin// Data fresh signal trigers this state and lock it in receiving mode
				if (uart_byte_counter <= 4'hF) begin
					next_state <= RECEIVING;
					if (uart_rx_data_fresh == 1'b1) begin
						uart_byte_counter = uart_byte_counter + 1'b1;
						data_in = (data_in << 4'h8) | uart_rx_data;
					end
				end
				else begin
					next_state <= IDLE;
					input_data_valid <= 1'b1;
				end
			end
			TRANSMITTING: begin // lets transmit
				if (uart_byte_counter <= 4'hF) begin
					next_state <= TRANSMITTING;
					if (uart_tx_data_ack == 1'b1) begin
						uart_tx_data_valid <= 1'b0;
						uart_byte_counter <= uart_byte_counter + 1'b1;
					end
					else if (uart_tx_data_valid == 1'b0) begin
					   temp_out = {temp_out[119:0], temp_out[127:120]};
					    uart_tx_data = temp_out[7:0]; 
						uart_tx_data_valid <= 1'b1;
					end
				end
				else begin
					next_state <= IDLE;// Go and wait for RX
				end
			end
		endcase
	end
end

endmodule
