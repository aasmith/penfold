module CoveredCallExpiryOtmExit
  def proceeds
    stock_sale
  end

  def explain
    template = <<-EOT
    Call Expires OTM
    Stock Sale %s (%s per share)
  - Net Outlay %s
  =     Profit %s
    EOT

    template % [
      stock_sale.to_money_s.rjust(12), 
      proceeds_per_share.to_money_s, 
      opening_position.net_outlay.to_money_s.rjust(12), 
      profit.to_money_s.rjust(12)
    ]
  end
end

