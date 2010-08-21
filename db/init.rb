require "rubygems"
require "sequel"

DB = Sequel.sqlite("options.sqlite")

DB.create_table :covered_calls do
  primary_key :id

  Date    :quote_date, :null => false
  Integer :days, :null => false

  String  :stock, :null => false
  Float   :stock_price, :null => false # last

  String  :option, :null => false
  Float   :option_price, :null => false # bid

  Float   :implied_volatility, :null => false
  Float   :prob_max_profit, :null => false
  Float   :prob_profit, :null => false

  Float   :downside_protection, :null => false

  Float   :period_return, :null => false
  Float   :annual_return, :null => false

  Boolean :event, :null => false

  String  :label
  String  :mktcap
  String  :name

  index :annual_return
  index :downside_protection
  index :prob_max_profit

  unique [:quote_date, :stock, :option]
end

