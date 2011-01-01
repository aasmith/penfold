require 'option_calendar'
require 'test/unit'

class OptionCalendarTest < Test::Unit::TestCase

  # Saturday expiries
  EXPIRY_MONTHS = [
    [Date.parse("Jan 1 2010"), Date.parse("Jan 16 2010")],
    [Date.parse("Feb 1 2010"), Date.parse("Feb 20 2010")],
    [Date.parse("Mar 1 2010"), Date.parse("Mar 20 2010")],
    [Date.parse("Apr 1 2010"), Date.parse("Apr 17 2010")],
    [Date.parse("May 1 2010"), Date.parse("May 22 2010")],
    [Date.parse("Jun 1 2010"), Date.parse("Jun 19 2010")],
    [Date.parse("Jul 1 2010"), Date.parse("Jul 17 2010")],
    [Date.parse("Aug 1 2010"), Date.parse("Aug 21 2010")],
    [Date.parse("Sep 1 2010"), Date.parse("Sep 18 2010")],
    [Date.parse("Oct 1 2010"), Date.parse("Oct 16 2010")],
    [Date.parse("Nov 1 2010"), Date.parse("Nov 20 2010")],
    [Date.parse("Dec 1 2010"), Date.parse("Dec 18 2010")],

    [Date.parse("Jan 1 2011"), Date.parse("Jan 22 2011")],
    [Date.parse("Feb 1 2011"), Date.parse("Feb 19 2011")],
    [Date.parse("Mar 1 2011"), Date.parse("Mar 19 2011")],
    [Date.parse("Apr 1 2011"), Date.parse("Apr 16 2011")],
    [Date.parse("May 1 2011"), Date.parse("May 21 2011")],
    [Date.parse("Jun 1 2011"), Date.parse("Jun 18 2011")],
    [Date.parse("Jul 1 2011"), Date.parse("Jul 16 2011")],
    [Date.parse("Aug 1 2011"), Date.parse("Aug 20 2011")],
    [Date.parse("Sep 1 2011"), Date.parse("Sep 17 2011")],
    [Date.parse("Oct 1 2011"), Date.parse("Oct 22 2011")],
    [Date.parse("Nov 1 2011"), Date.parse("Nov 19 2011")],
    [Date.parse("Dec 1 2011"), Date.parse("Dec 17 2011")]
  ]

  def test_monthly_expirations
    EXPIRY_MONTHS.each do |month, exp|
      message = "Month #{month.strftime("%b")} should have expiry of #{exp}"

      assert_equal exp, OptionCalendar.expiration_for(month), message
      assert_equal exp, OptionCalendar.expiration_for(month.end_of_month), message
    end
  end

  NEXT_MONTHS = [
    [Date.parse("Sep 15 2010"), Date.parse("Sep 18 2010"), Date.parse("Oct 16 2010")],
    [Date.parse("Sep 16 2010"), Date.parse("Sep 18 2010"), Date.parse("Oct 16 2010")],
    [Date.parse("Sep 17 2010"), Date.parse("Oct 16 2010"), Date.parse("Nov 20 2010")],
    [Date.parse("Sep 18 2010"), Date.parse("Oct 16 2010"), Date.parse("Nov 20 2010")],
    [Date.parse("Sep 19 2010"), Date.parse("Oct 16 2010"), Date.parse("Nov 20 2010")]
  ]

  def test_next_expiring_months
    NEXT_MONTHS.each do |date, *expected|
      message = "#{date} should have expirations #{expected.inspect}"

      assert_equal expected, OptionCalendar.next_expiring_months(date), message
    end
  end

  def test_nearest_expiration
    jan_expiry = OptionCalendar.expiration_for(Date.parse("Jan 2011"))
    feb_expiry = OptionCalendar.expiration_for(Date.parse("Feb 2011"))

    assert_equal jan_expiry, OptionCalendar.nearest_expiration(jan_expiry - 4.days, 3.days)
    assert_equal feb_expiry, OptionCalendar.nearest_expiration(jan_expiry - 3.days, 3.days)
    assert_equal feb_expiry, OptionCalendar.nearest_expiration(jan_expiry - 2.days, 3.days)

    assert_equal jan_expiry, OptionCalendar.nearest_expiration(Date.parse("Dec 31 2010"), 3.days)
    assert_equal feb_expiry, OptionCalendar.nearest_expiration(Date.parse("Dec 31 2010"), 30.days)
    assert_equal feb_expiry, OptionCalendar.nearest_expiration(Date.parse("Nov 30 2010"), 60.days)
  end

end

