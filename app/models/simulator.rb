class Simulator

  Holding = Struct.new(:name, :quantity, :price)

  def initialize(currencies_to_buy)
    @trade_taker_fee = 0.0025
    @trade_maker_fee = 0.0015
    @trade_frequency = 4.hours # We only have data for every 4 hours so must be 4,8,12,24,etc
    @start_time = Time.utc(2016, 7, 13)
    @end_time = Price.where(name: Portfolio.reference_currency).maximum(:timestamp)
    @start_usd = 5000.00
    @currencies_to_buy = currencies_to_buy

    # Verify we have data that goes far enough back for each currency
    @currencies_to_buy.each do |name|
      price = Price.where(name: name, timestamp: @start_time).take
      raise "Don't have currency data going back to #{@start_time} for #{name}" unless price != nil
    end
  end

  def run(algorithm)
    raise "Algorithm cannot be nil" if algorithm == nil
    holdings = @currencies_to_buy.map { |name| Holding.new(name)}

    # Show the stats
    bitcoin_price_at_start = Price.where(name: Portfolio.reference_currency, timestamp: @start_time).take.weighted_average
    bitcoin_holdings_at_start = @start_usd / bitcoin_price_at_start
    puts "Starting #{algorithm.class} simulation at #{@start_time}"
    puts "Bitcoin holdings to start #{bitcoin_holdings_at_start.truncate(3).to_s} BTC worth $#{@start_usd} at $#{bitcoin_price_at_start.truncate(3).to_s}/BTC"

    # Prepare the portfolio
    bitcoin_per_holding = bitcoin_holdings_at_start / holdings.count
    holdings.each do |holding|
      buy(holding, bitcoin_per_holding, @start_time)
    end

    puts "\nPrepared the following portfolio:"
    print_holdings(holdings, @start_time)

    # Run the simulation
    puts "Starting simulation (T means traded and _ means nothing happened):"
    current_time = @start_time + @trade_frequency
    while current_time <= @end_time do
      algorithm.run(self, holdings, current_time)
      current_time += @trade_frequency
    end
    puts

    # Show the results
    puts "\nPortfolio at the end of the simulation:"
    usd_value_at_end = print_holdings(holdings, @end_time)
    percentage = usd_value_at_end / @start_usd
    puts "TOTAL_PCT_RETURN #{(percentage * 100).truncate(2)}%"
    puts "Simulation #{algorithm.class} completed at #{@end_time}\n\n"
    return percentage
  end

  def run_holding_btc
    # Show the stats
    bitcoin_price_at_start = Price.where(name: Portfolio.reference_currency, timestamp: @start_time).take.weighted_average
    bitcoin_holdings_at_start = @start_usd / bitcoin_price_at_start
    puts "Bitcoin holdings to start #{bitcoin_holdings_at_start.truncate(3).to_s} BTC worth $#{@start_usd} at $#{bitcoin_price_at_start.truncate(3).to_s}/BTC"

    bitcoin_price_at_end = Price.where(name: Portfolio.reference_currency, timestamp: @end_time).take.weighted_average
    usd_value_at_end = bitcoin_holdings_at_start * bitcoin_price_at_end

    puts "Holding just BTC for the same period would give you #{bitcoin_holdings_at_start.truncate(3)} BTC worth $#{usd_value_at_end.truncate(2)} at $#{bitcoin_price_at_end.truncate(3).to_s}/BTC"
    return usd_value_at_end / @start_usd
  end

  def sell(holding, amount_of_btc, timestamp)
    if holding.price == nil || holding.price.timestamp != timestamp
      holding.price = Price.where(name: holding.name, timestamp: timestamp).take
    end
    price_of_holding = holding.price.weighted_average
    quantity_to_sell = amount_of_btc / price_of_holding
    holding.quantity = holding.quantity - quantity_to_sell
    quantity_sold_after_fees = quantity_to_sell - (quantity_to_sell * @trade_maker_fee)
    btc_we_end_up_with_after_sale = quantity_sold_after_fees * price_of_holding
    btc_we_end_up_with_after_sale
  end

  def buy(holding, amount_of_btc, timestamp)
    if holding.price == nil || holding.price.timestamp != timestamp
      holding.price = Price.where(name: holding.name, timestamp: timestamp).take
    end
    price_of_holding = holding.price.weighted_average
    quantity_to_buy = amount_of_btc / price_of_holding
    fees = quantity_to_buy * @trade_taker_fee
    if holding.quantity == nil
      holding.quantity = 0.0
    end
    holding.quantity = holding.quantity + (quantity_to_buy - fees)
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

  def print_holdings(holdings, timestamp)
    holdings.each do |holding|
      holding_value_btc = holding.quantity * holding.price.weighted_average
      puts "#{holding.name} #{holding.quantity.truncate(5).to_s} #{holding_value_btc.truncate(5)} BTC"
    end
    holdings_value_btc = holdings_value_in_btc(holdings, timestamp)
    holdings_value_usd = Price.where(name: Portfolio.reference_currency, timestamp: timestamp).take.weighted_average * holdings_value_btc
    puts "TOTAL_BTC #{holdings_value_btc.truncate(4)} = $#{holdings_value_usd.truncate(2)}\n\n"
    return holdings_value_usd
  end

end
