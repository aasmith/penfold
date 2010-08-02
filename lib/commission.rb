class Commission
  include ArgumentProcessor

  attr_accessor :option_entry, :stock_entry,
    :option_entry_per_contract,
    :option_assignment

  def initialize(args = {})
    process_args(args)
  end

  def total_option_entry(num_shares)
    option_entry + ((num_shares / 100) * option_entry_per_contract)
  end

  OPTIONS_HOUSE = new(
    :stock_entry => 2_95, 
    :option_entry => 8_50, 
    :option_entry_per_contract => 15,
    :option_assignment => 5_00
  )

  OPTIONS_HOUSE_ALT = new(
    :stock_entry => 2_95, 
    :option_entry => 5_00, 
    :option_entry_per_contract => 1_00,
    :option_assignment => 5_00
  )

  TRADE_KING = new(
    :stock_entry => 4_95, 
    :option_entry => 4_95, 
    :option_entry_per_contract => 65,
    :option_assignment => 4_95
  )

  SCOTTRADE = new(
    :stock_entry => 7_00, 
    :option_entry => 7_00, 
    :option_entry_per_contract => 1_25,
    :option_assignment => 17_00
  )

  ETRADE = new(
    :stock_entry => 9_99, 
    :option_entry => 9_99, 
    :option_entry_per_contract => 75,
    :option_assignment => 19_99
  )

  # $5min, $9.95 max, upto 5,000 shares $0.015
  THINK_OR_SWIM = new(
    :stock_entry => 1.5, # one and a half pennies
    :option_entry => 4_95, 
    :option_entry_per_contract => 65,
    :option_assignment => 15_00 # per strike
  )

  FREE = new(
    :stock_entry => 0, 
    :option_entry => 0, 
    :option_entry_per_contract => 0,
    :option_assignment => 0
  )
end

