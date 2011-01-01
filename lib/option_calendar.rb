# Finds upcoming expiry dates for monthly equity options.
#
# Test data is the official CBOE expiration calendars for 2010/11.

require 'date'

require 'rubygems'
require 'active_support'

class OptionCalendar
  class << self
    FRIDAY = 5

    def expiration_for(month)
      start = month.beginning_of_month

      expiry_week = start.advance(:days => 14)

      expiry_week += 1.day while expiry_week.wday != FRIDAY

      expiry_saturday = expiry_week + 1.day
    end

    def next_expiring_months(from = Date.today)
      this_month = expiration_for(from)
      next_month = expiration_for(from.next_month)

      expirations = [
        this_month,
        next_month
      ]

      # If the first month has already expired, remove it, and add another month out
      if from >= (this_month - 1.day)
        expirations.shift
        expirations << expiration_for(next_month.next_month)
      end

      expirations
    end
  
    def nearest_expiration(date, range = 3.days)
      expiration_date = expiration_for(date + range)

      if date > expiration_date
        expiration_date = expiration_for(expiration_date.next_month)
      end

      if date >= expiration_date - range
        expiration_for(expiration_date.next_month)
      else
        expiration_date
      end
    end
  end
end
