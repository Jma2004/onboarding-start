module spi_peripheral (
    input wire        clk,
    input wire        rst_n,
    input wire        ncs,
    input wire        sclk,
    input wire        copi,
    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);
localparam MAX_ADDRESS = 4'b1111;
reg [3:0] counter = 4'b0000;
reg [6:0] address = 7'b0000000;
reg [7:0] data = 8'b00000000;
reg transaction_ready = 1'b0;
reg transaction_processed = 1'b0;
reg ncs_sync_1;
reg ncs_sync_2;
reg sclk_sync_1;
reg sclk_sync_2;
reg copi_sync_1, copi_sync_2;
wire sclk_pos_edge, ncs_posedge;
assign sclk_pos_edge = (sclk_sync_1 == 1 && sclk_sync_2 == 0) ? 1 : 0;
assign ncs_posedge = (ncs_sync_1 == 0 && ncs_sync_2 == 1) ? 1 : 0;
//2 stage ff chain    
always @ (posedge clk) begin
    if (!rst_n) begin
        ncs_sync_1 <= 1'b1;
        ncs_sync_2 <= 1'b1;
        sclk_sync_1 <= 1'b0;
        sclk_sync_2 <= 1'b0;
        copi_sync_1 <= 1'b0;
        copi_sync_2 <= 1'b0;
    end else begin
        ncs_sync_1 <= ncs;
        ncs_sync_2 <= ncs_sync_1;
        sclk_sync_1 <= sclk;
        sclk_sync_2 <= sclk_sync_1;
        copi_sync_1 <= copi;
        copi_sync_2 <= copi_sync_1;
    end
end

// Process SPI protocol in the clk domain
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 4'b0000;
        address <= 7'b0000000;
        data <= 8'b00000000;
        transaction_ready <= 1'b0;
    end else if (ncs_sync_2 == 1'b0) begin
        if(sclk_pos_edge)begin
            if (counter == 0)begin
                //consume r/w bit
            end else if (counter <= 7) begin
                address <= {copi_sync_2, address[5:0]};
            end else begin
                data <= {copi_sync_2, data[6:0]};
            end
            counter <= counter + 1;
        end
    end else begin
        // When nCS goes high (transaction ends), validate the complete transaction
        if (ncs_posedge) begin
            transaction_ready <= 1'b1;
            counter <= 0;
        end else if (transaction_processed) begin
            // Clear ready flag once processed
            transaction_ready <= 1'b0;
        end
        // omitted code
    end
end

// Update registers only after the complete transaction has finished and been validated
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // omitted code
        transaction_processed <= 1'b0;
        en_reg_pwm_7_0 <= 0;
        en_reg_pwm_15_8 <= 0;
        en_reg_out_7_0 <= 0;
        en_reg_out_15_8 <= 0;
        en_reg_pwm_7_0 <= 0;
        en_reg_pwm_15_8 <= 0;
    end else if (transaction_ready && !transaction_processed) begin
        // Transaction is ready and not yet processed
        if(address <= 4)begin
            if(address == 0)begin
                en_reg_pwm_7_0 <= 0;
                en_reg_pwm_15_8 <= 0;
                en_reg_out_7_0 <= data;
                en_reg_out_15_8 <= 0;
                pwm_duty_cycle <= 0;
            end else if (address == 1) begin
                en_reg_pwm_7_0 <= 0;
                en_reg_pwm_15_8 <= 0;
                en_reg_out_7_0 <= 0;
                en_reg_out_15_8 <= data;
                pwm_duty_cycle <= 0;
            end else if (address == 2) begin
                en_reg_pwm_7_0 <= data;
                en_reg_pwm_15_8 <= 0;
                en_reg_out_7_0 <= 0;
                en_reg_out_15_8 <= 0;
                pwm_duty_cycle <= 0;
            end else if (address == 3) begin
                en_reg_pwm_7_0 <= 0;
                en_reg_pwm_15_8 <= data;
                en_reg_out_7_0 <= 0;
                en_reg_out_15_8 <= 0;
                pwm_duty_cycle <= 0;
            end else if (address == 4) begin
                en_reg_pwm_7_0 <= 0;
                en_reg_pwm_15_8 <= 0;
                en_reg_out_7_0 <= 0;
                en_reg_out_15_8 <= 0;
                pwm_duty_cycle <= data;
            end
        end
        // Set the processed flag
        transaction_processed <= 1'b1;
    end else if (!transaction_ready && transaction_processed) begin
        // Reset processed flag when ready flag is cleared
        transaction_processed <= 1'b0;
    end
end
endmodule