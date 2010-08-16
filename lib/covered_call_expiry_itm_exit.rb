module CoveredCallExpiryItmExit
  def proceeds
    exercise
  end

  def explain
    template = <<-EOT
    Call Expires ITM
           Exercise %s (inc %s Assignment Fee)
  =    Net Proceeds %s (%s per share)
  -      Net Outlay %s
  =          Profit %s

    EOT

    template % [
      exercise.to_money_s.rjust(12), 
      commission.option_assignment.to_money_s,
      proceeds.to_money_s.rjust(12), 
      proceeds_per_share.to_money_s, 
      opening_position.net_outlay.to_money_s.rjust(12), 
      profit.to_money_s.rjust(12)
    ]
  end
end

