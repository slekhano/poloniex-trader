class Algorithms::RebalanceStandard

  Holding = Struct.new(:name, :quantity, :price)

  @starting_currency = 'USDT_BTC'

  def run
    @starting_currency = 'USDT_BTC'
    frequency = 4.hours
    start_time = Time.utc(2016, 1, 1)
    end_time = Price.where(name: @starting_currency).maximum(:timestamp)
    start_usd = 5000.00
    holdings = [Holding.new("BTC_ETH"), Holding.new("BTC_LTC")]
    trade_fee = 0.0025

    # Show the stats
    bitcoin_price_at_start = Price.where(name: @starting_currency, timestamp: start_time).take.weighted_average
    bitcoin_holdings_at_start = start_usd / bitcoin_price_at_start
    puts "Bitcoin holdings to start #{bitcoin_holdings_at_start.truncate(3).to_s} BTC worth $#{start_usd} at $#{bitcoin_price_at_start.truncate(3).to_s}/BTC"

    # Prepare the portfolio
    bitcoin_per_holding = bitcoin_holdings_at_start / holdings.count
    holdings.each do |holding|
      buy(holding, bitcoin_per_holding, trade_fee, start_time)
    end
    puts "\nPrepared the following portfolio"
    print_holdings(holdings, start_time)

    # Run the simulation
    current_time = start_time + frequency
    while current_time <= end_time do
      print "."
      rebalance(holdings, current_time)
      current_time += frequency
    end
    puts

    # Show the results
    print_holdings(holdings, end_time)
    bitcoin_price_at_end = Price.where(name: @starting_currency, timestamp: end_time).take.weighted_average
    usd_value_at_end = bitcoin_holdings_at_start * bitcoin_price_at_end
    puts "Holding BTC for the same period would give you #{bitcoin_holdings_at_start.truncate(3)} BTC worth $#{usd_value_at_end.truncate(2)}"
  end

  def rebalance(holdings, timestamp)
    btc_value = holdings_value_in_btc(holdings, timestamp)
    btc_per_holding = btc_value / holdings.count

  end

  def holdings_value_in_btc(holdings, timestamp)
    btc_value = 0.0
    holdings.each do |holding|
      update_holding(holding, timestamp)
      btc_value += holding.quantity * holding.price.weighted_average
    end
    btc_value
  end

  def update_holding(holding, timestamp)
    holding.price = Price.where(name: holding.name, timestamp: timestamp).take
  end

  def buy(holding, amount_of_btc, trade_fee, timestamp)
    price_of_holding = Price.where(name: holding.name, timestamp: timestamp).take.weighted_average
    quantity_to_buy = amount_of_btc / price_of_holding
    fees = quantity_to_buy * trade_fee
    holding.quantity = quantity_to_buy - fees
  end

  def print_holdings(holdings, timestamp)
    holdings.each do |holding|
      puts "#{holding.name} #{holding.quantity.truncate(5).to_s}"
    end
    holding_value_btc = holdings_value_in_btc(holdings, timestamp)
    holding_value_usd = Price.where(name: @starting_currency, timestamp: timestamp).take.weighted_average * holding_value_btc
    puts "TOTAL_BTC #{holding_value_btc.truncate(4)} = $#{holding_value_usd.truncate(2)}"
  end
end