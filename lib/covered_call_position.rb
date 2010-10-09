class CoveredCallPosition
  include ArgumentProcessor

  attr_accessor :num_shares, :date_established, :option

  def initialize(args = {})
    process_args(args)
  end

  def commission=(name)
    @commission = name.to_s
  end

  def commission
    @commission_instance ||= Commission.const_get(@commission).new(
      :shares => num_shares, :contracts => num_shares / 100
    )
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
    num_shares * option.price - commission.option_entry
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

  def implied_volatility
    @iv ||= BlackScholes.call_iv(
      stock.price / 100.0, 
      option.strike / 100.0, 
      0.27, # TODO: risk-free rate
      option.days_to_expiry(date_established),
      option.price / 100.0
    )
  end

  def probability_max_profit
    BlackScholes.probability_above(
      stock.price / 100.0,
      option.strike / 100.0,
      option.days_to_expiry(date_established),
      implied_volatility
    )
  end

  def probability_profit
    BlackScholes.probability_above(
      stock.price / 100.0,
      net_per_share / 100.0,
      option.days_to_expiry(date_established),
      implied_volatility
    )
  end

#  def exit(exit_date = Date.today + 1, stock_price = stock.price)
#    CoveredCallExit.new(
#      :opening_position => self,
#      :stock_price => stock_price,
#      :exit_date => exit_date
#    )
#  end
end

