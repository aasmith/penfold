require 'rubygems'
require 'sequel'
require 'penfold'

filename = ARGV[0]

symbols = if filename
  File.read(filename).
               split(/\n/).
               map{|s| s.strip}.
               reject{|s|s =~ /^#/}
else
  %w(VZ C GE DVY PGR COCO BP RIG)
end

# series is the option symbol timestamp,
# such as 100821, 100918, etc.
series = ARGV[1]
expiry = Date.strptime series, "%y%m%d"

today = Date.today

quote_date = if [6,0].include?(today.wday)
  # weekend, wind back to friday
  today - (today.wday.zero? ? 2 : 1)
else
  today
end

puts "Quote date is #{quote_date.inspect}"

INVESTMENT_AMOUNT = 10_000_00 # $10,000.00

DB = Sequel.sqlite("options.sqlite")
calls = DB[:covered_calls]

symbols.each do |symbol|
  puts "== #{symbol} ====================="

  begin
    # Get a delayed quote, as option quotes are delayed.
    stock_quote = Market.fetch(symbol, :try_rt => false, :extra => true)
  rescue
    puts "Error getting #{symbol}"
    puts $!
    next
  end

  stock = Stock.new(:symbol => symbol, :price => stock_quote.last)

  num_shares = ((INVESTMENT_AMOUNT / stock.price) / 100.0).floor * 100

  if num_shares.zero?
    puts "Skipping because #{INVESTMENT_AMOUNT.to_money_s} will not buy any shares of #{symbol} @ #{stock.price.to_money_s}."
    next
  end

  begin
    itm_option_quotes = Market.chain(symbol, expiry)
  rescue
    puts "No options for #{symbol}"
    puts $!
    next
  end

  event = Market.event?(symbol, expiry)

  current_price = stock.price / 100.0
  prices = Market.historical_prices(symbol)

  above = prices.select { |price| price >= current_price }
  percent_above = above.size / prices.size.to_f

  itm_options = itm_option_quotes.map do |strike, option_quote|
    Call.new(
      :symbol => option_quote.symbol,
      :stock => stock,
      :strike => strike,
      :expires => expiry,
      :price => option_quote.bid, # TODO: parametize
      :current_date => quote_date
    )
  end

  positions = itm_options.map do |option|
    CoveredCallPosition.new(
      :commission => "OptionsHouse",
      :num_shares => num_shares,
      :date_established => Date.today,
      :option => option
    )
  end

  # Get the IV for the nearest ot the money ITM option. If this comes back as 
  # N/A, then the option is probably too far from the money to have an IV.
  # (example C @ 3.95, ITM option is at 3 strike with few days left)
  nearest_atm_iv = positions.last.implied_volatility rescue 0.0

  positions.each { |p| p.instance_variable_set "@iv", nearest_atm_iv }

  positions.each do |position|
    close = CoveredCallExit.new(
      :opening_position => position,
      :exit_date => Date.today + 99999,
      :stock_price => stock.price,
      :option_price => position.option.price
    )

    summary = <<-SUMMARY
%s @ %s: %s @ %s  IV %s 
Prob. (Max) profit  (%s) %s
Downside Protection %s
Return (period) ann (%s) %s %s
SUMMARY

    r = close.annualized_return

    if r > 0.12
      puts summary % [
        stock.symbol,
        stock.price.to_money_s,
        position.option.to_ticker_s,
        position.option.price.to_money_s,

        position.implied_volatility.to_percent_s(2),
        position.probability_max_profit.to_percent_s(2),
        position.probability_profit.to_percent_s(2),

        position.downside_protection.to_percent_s(2),

        close.period_return.to_percent_s(2),
        r.to_percent_s(2),
        event ? "EVENT IN DURATION" : ""
      ]

      calls.insert(
        :quote_date          => quote_date,
        :days                => close.days_in_position,
        :stock               => stock.symbol,
        :stock_price         => stock.price / 100.0,
        :option              => position.option.to_ticker_s,
        :option_price        => position.option.price / 100.0,
        :implied_volatility  => position.implied_volatility * 100.0,
        :prob_max_profit     => position.probability_max_profit * 100.0,
        :prob_profit         => position.probability_profit * 100.0,
        :downside_protection => position.downside_protection * 100.0,
        :period_return       => close.period_return * 100.0,
        :annual_return       => close.annualized_return * 100.0,
        :event               => event,
        :label               => File.split(filename).last,
        :mktcap              => stock_quote.extra[:mktcap],
        :name                => stock_quote.extra[:name],
        :divyield            => stock_quote.extra[:divyield],
        :pe                  => stock_quote.extra[:pe],
        :sector              => stock_quote.extra[:sector],
        :industry            => stock_quote.extra[:industry],
        :percent_above       => percent_above * 100.0
      )
    end
  end
end
