class CoveredCallExit
  include ArgumentProcessor

  attr_reader :opening_position, :option

  def initialize(args = {})
    @opening_position = args[:opening_position]

    @option = opening_position.option.dup
    @option.stock = opening_position.stock.dup

    stock.price = args[:stock_price] if args[:stock_price]
    option.price = args[:option_price] if args[:option_price]
    option.current_date = args[:exit_date] if args[:exit_date]

    raise ArgumentError, "Stock does not match" unless stock == opening_position.stock
    raise ArgumentError, "Option does not match" unless option == opening_position.option

    extend exit_type
  end

  def exit_type
    if    option.expired? and option.in_the_money?  then CoveredCallExpiryItmExit
    elsif option.expired? and option.out_the_money? then CoveredCallExpiryOtmExit
    else                                                 CoveredCallEarlyExit
    end
  end

  def days_in_position
    ([option.expires, option.current_date].min - opening_position.date_established).to_i
  end

  def annualized_return
    #(1 + period_return) ** (1 / (opening_position.option.days_to_expiry/365.0)) - 1
    (1 + period_return) ** (1 / (days_in_position/365.0)) - 1
  end

  def period_return
    profit / opening_position.net_outlay.to_f
  end

  def profit
    proceeds - opening_position.net_outlay
  end

  def proceeds
    raise NotImplementedError
  end

  def proceeds_per_share
    proceeds / num_shares
  end

  def stock
    option.stock
  end

  def commission
    opening_position.commission
  end

  def num_shares
    opening_position.num_shares
  end

  def num_options
    opening_position.num_options
  end

  def exit_date
    opening_position.date_established + days_in_position
  end

  def exercise
    (num_shares * option.strike) - commission.option_assignment
  end

  def stock_sale
    (num_shares * stock.price) - commission.stock_entry
  end

  def option_sale
    (num_shares * option.price) - commission.total_option_entry(num_shares)
  end
end

