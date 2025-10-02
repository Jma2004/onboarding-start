module spi_peripheral (
    input wire        clk,
    input wire        ncs,
    input wire        sclk,
    input wire        copi,
    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);
localparam MAX_ADDRESS = 4;
reg [3:0] counter  = 0;
reg [6:0] address;
reg [7:0] data;
reg transaction_complete;
reg r_ncs_1, r_ncs_2,
    r_sclk_1, r_sclk_2,
    r_copi_1, r_copi_2;

//2 stage ff chain
always @ (posedge clk)begin
    r_ncs_1 <= ncs;
    r_ncs_2 <= r_ncs_1;

    r_sclk_1 <= sclk;
    r_sclk_2 <= r_sclk_1;

    r_copi_1 <= copi;
    r_copi_2 <= r_copi_1;
end

always @ (posedge r_sclk_2) begin
    //sample data
    if(r_ncs_2)begin
        counter <= 0;
        address <= 0;
        data <= 0;
        transaction_complete <= 0;
    end else begin
        if (counter == 0)begin
            //sample R/W bit
        end else if(counter <= 7) begin
            address[counter - 1] <= r_copi_2; 
        end else begin
            data[counter - 8] <= r_copi_2;
        end
        counter <= counter + 1;
        if (counter == 15) transaction_complete <= 1;
    end
end

always @ (posedge r_ncs_2) begin
    if (transaction_complete && address <= MAX_ADDRESS) begin
        if (address == 0) begin
            en_reg_out_7_0 <= data;
            en_reg_out_15_8 <= 0;
            en_reg_pwm_7_0 <= 0;
            en_reg_pwm_15_8 <= 0;
            pwm_duty_cycle <= 0;
        end else if (address == 1) begin
            en_reg_out_7_0 <= 0;
            en_reg_out_15_8 <= data;
            en_reg_pwm_7_0 <= 0;
            en_reg_pwm_15_8 <= 0;
            pwm_duty_cycle <= 0;
        end else if (address == 2) begin
            en_reg_out_7_0 <= 0;
            en_reg_out_15_8 <= 0;
            en_reg_pwm_7_0 <= data;
            en_reg_pwm_15_8 <= 0;
            pwm_duty_cycle <= 0;
        end else if (address == 3) begin
            en_reg_out_7_0 <= 0;
            en_reg_out_15_8 <= 0;
            en_reg_pwm_7_0 <= 0;
            en_reg_pwm_15_8 <= data;
            pwm_duty_cycle <= 0;
        end else if (address == 4) begin
            en_reg_out_7_0 <= 0;
            en_reg_out_15_8 <= 0;
            en_reg_pwm_7_0 <= 0;
            en_reg_pwm_15_8 <= 0;
            pwm_duty_cycle <= data;
        end
    end 
end

endmodule