require "test/unit"
require "flexmock/test_unit"
require "penfold"

class TestPenfold < Test::Unit::TestCase
  # commission
  def test_total_option_commission
    commission = Commission.new(
      :stock_entry => 2_95, 
      :option_entry => 8_50, 
      :option_entry_per_contract => 15,
      :option_assignment => 5_00)

    assert_equal 8_50 + 15, commission.total_option_entry(100)
    assert_equal 8_50 + 30, commission.total_option_entry(200)
  end

  # options
  def test_call_type
    call = Call.new

    assert call.call?
    assert !call.put?
  end

  def test_put_type
    put = Put.new

    assert !put.call?
    assert put.put?
  end

  def test_option_cannot_be_instantiated
    assert_raise ArgumentError do
      Option.new
    end
  end

  def test_option_expiry
    unexpired     = Call.new(:expires => Date.today + 10)
    expired       = Call.new(:expires => Date.today - 10)
    expires_today = Call.new(:expires => Date.today)

    assert !unexpired.expired?
    assert_equal 10, unexpired.days_to_expiry

    assert expired.expired?
    assert_equal 0, expired.days_to_expiry

    assert !expires_today.expired?
    assert_equal 0, expires_today.days_to_expiry
  end

  def test_to_s
    expires = Date.today + 93

    stock = Stock.new(:symbol => "XYZ", :price => 50_00)

    option = Call.new(
      :stock => stock, 
      :strike => 35_00, 
      :expires => expires,
      :price => 4_50
    )

    assert_equal "XYZ 35 #{expires.strftime("%b %y").upcase} CALL", option.to_s, 
      "A whole dollar amount does not require a floating point strike price"
    
    option = Call.new(
      :stock => stock, 
      :strike => 5_50, 
      :expires => expires,
      :price => 4_50
    )

    assert_equal "XYZ 5.5 #{expires.strftime("%b %y").upcase} CALL", option.to_s, 
      "A partial dollar amount requires a floating point strike price"
  end

  def test_out_the_money?
    assert flexmock(Call.new, :in_the_money? => false).out_the_money?
    assert !flexmock(Call.new, :in_the_money? => true).out_the_money?
  end

  def test_call_moneyness
    call = Call.new(:strike => 5_00, :stock => Stock.new(:price => 4_90))

    assert !call.in_the_money?
    assert !call.at_the_money?

    call.stock.price += 10
    assert !call.in_the_money?
    assert call.at_the_money?

    call.stock.price += 10
    assert call.in_the_money?
    assert !call.at_the_money?
  end

  def test_put_moneyness
    put = Put.new(:strike => 5_00, :stock => Stock.new(:price => 4_90))

    assert put.in_the_money?
    assert !put.at_the_money?

    put.stock.price += 10
    assert !put.in_the_money?
    assert put.at_the_money?

    put.stock.price += 10
    assert !put.in_the_money?
    assert !put.at_the_money?
  end

  # position

  def test_stock_total
    position = CoveredCallPosition.new(
      :num_shares => 500, 
      :option => Call.new(:stock => Stock.new(:price => 50_00)), 
      :commission => commission
    )
    
    assert_equal 500 * 50_00 + STOCK_ENTRY, position.stock_total
  end

  def test_call_sale
    position = CoveredCallPosition.new(
      :num_shares => 500,
      :option => Call.new(:price => 6_00),
      :commission => commission
    )

    assert_equal 3_000_00 - (OPTION_ENTRY + 5 * PER_CONTRACT), position.call_sale
  end

  def test_net_outlay
    position = flexmock(
      CoveredCallPosition.new, 
      :stock_total => 25_000_00 + STOCK_ENTRY, 
      :call_sale => 3_000_00 - (OPTION_ENTRY + 5 * PER_CONTRACT)
    )

    assert_equal 22_012_20, position.net_outlay
  end

  def test_net_per_share
    position = CoveredCallPosition.new(:num_shares => 500)
    flexmock(position, :net_outlay => 22_012_20)

    assert_equal 44_02.44, position.net_per_share
  end

  def test_downside_protection
    position = flexmock(
      CoveredCallPosition.new, 
      :net_per_share => 44_00, 
      :stock => Stock.new(:price => 50_00)
    )

    assert_equal(-0.12, position.downside_protection, "should be -12%")
  end

  def test_odd_lots
    assert_raise ArgumentError do
      CoveredCallPosition.new(:num_shares => 23)
    end

    assert_nothing_raised do
      CoveredCallPosition.new(:num_shares => 100)
    end
  end

  def test_num_options
    assert 3, CoveredCallPosition.new(:num_shares => 300)
  end

  def test_stock
    stock = Stock.new
    position = CoveredCallPosition.new(:option => Put.new(:stock => stock))

    assert_equal stock, position.stock
  end

  # exit

  def test_creation
    date = Date.today

    position = CoveredCallPosition.new(
      :num_shares => 500,
      :commission => Commission::OPTIONS_HOUSE,
      :date_established => date,

      :option => Call.new(
        :expires => date + 30,
        :strike  => 50_00,
        :price   => 6_00,
        :stock => Stock.new(
          :symbol => "XYZ",
          :price => 50_00
        )
      )
    )

    closing_position = CoveredCallExit.new(
      :opening_position => position,
      :exit_date => date + 34,
      :stock_price => 55_00
    )

    assert_not_same position.stock, closing_position.stock
    assert_equal position.stock, closing_position.stock

    assert_not_same position.option, closing_position.option
    assert_equal position.option, closing_position.option

    assert_same position.commission, closing_position.commission
    
    assert_equal date + 30, closing_position.exit_date
    assert closing_position.option.expired?

    assert_equal 55_00, closing_position.stock.price
  end

  def test_creates_expired_position_when_expired_in_the_money
    position = CoveredCallPosition.new(
      :option => Call.new(
        :stock => Stock.new(:price => 48_00),
        :strike => 50_00,
        :expires => Date.today + 10
      )
    )

    expired_itm = CoveredCallExit.new(
      :opening_position => position,
      :stock_price => 52_00,
      :exit_date => Date.today + 11
    )

    expired_otm = CoveredCallExit.new(
      :opening_position => position,
      :stock_price => 48_00,
      :exit_date => Date.today + 11
    )

    unexpired_itm = CoveredCallExit.new(
      :opening_position => position,
      :stock_price => 52_00,
      :exit_date => Date.today + 1
    )

    unexpired_otm = CoveredCallExit.new(
      :opening_position => position,
      :stock_price => 48_00,
      :exit_date => Date.today + 1
    )

    assert_kind_of CoveredCallExpiryItmExit, expired_itm
    assert !expired_otm.kind_of?(CoveredCallExpiryItmExit)
    assert !unexpired_itm.kind_of?(CoveredCallExpiryItmExit)
    assert !unexpired_otm.kind_of?(CoveredCallExpiryItmExit)
  end

  def test_no_profit_method_body_for_default_class
    assert_raise NotImplementedError do
      CoveredCallExit.allocate.profit
    end
  end

  # helpers

  STOCK_ENTRY = 2_95
  OPTION_ENTRY = 8_50
  PER_CONTRACT = 15

  def commission
    Commission.new(
      :stock_entry => STOCK_ENTRY, 
      :option_entry => OPTION_ENTRY, 
      :option_entry_per_contract => PER_CONTRACT,
      :option_assignment => 5_00
    )
  end
end
