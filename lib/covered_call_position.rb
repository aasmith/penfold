class CoveredCallPosition
  include ArgumentProcessor

  attr_accessor :num_shares, :date_established, :option, :commission

  def initialize(args = {})
    process_args(args)
  end

  undef num_shares=
  def num_shares=(num)
    raise ArgumentError, "Shares must be assigned in lots of 100." unless num % 100 == 0
    @num_shares = num
  end

  def stock_total
    num_shares * stock.price + commission.stock_entry
  end

  def call_sale
    num_shares * option.price - commission.total_option_entry(num_shares)
  end

  def net_outlay
    stock_total - call_sale
  end

  def net_per_share
    net_outlay.to_f / num_shares
  end

  def downside_protection
    (net_per_share.to_f - stock.price) / stock.price
  end

  def stock
    option.stock
  end
  
#  def exit(exit_date = Date.today + 1, stock_price = stock.price)
#    CoveredCallExit.new(
#      :opening_position => self,
#      :stock_price => stock_price,
#      :exit_date => exit_date
#    )
#  end
end

