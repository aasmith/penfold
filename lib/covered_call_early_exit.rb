module CoveredCallEarlyExit
  def proceeds
    stock_sale - option_sale
  end

  def explain
    template = <<-EOT
    Early Exit
      Stock Sale %s
  - Call Buyback %s
  = Net Proceeds %s (%s per share)
  -   Net Outlay %s
  =       Profit %s
    EOT

    template % [
      stock_sale.to_money_s.rjust(12), 
      option_sale.to_money_s.rjust(12), 
      proceeds.to_money_s.rjust(12), 
      proceeds_per_share.to_money_s, 
      opening_position.net_outlay.to_money_s.rjust(12), 
      profit.to_money_s.rjust(12)
    ]
  end
end

