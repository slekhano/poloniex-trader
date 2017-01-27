class Algorithms::RebalanceStandard

  Holding = Struct.new(:name, :quantity, :price)

  def initialize
    @btc_leftover_balance = 0.0
    @starting_currency = 'USDT_BTC'
    @trade_taker_fee = 0.0025
    @trade_maker_fee = 0.0015
    @trade_frequency = 4.hours # We only have data for every 4 hours so must be 4,8,12,24,etc
  end

  def run
    start_time = Time.utc(2016, 7, 13)
    end_time = Price.where(name: @starting_currency).maximum(:timestamp)
    start_usd = 5000.00

    # Verify we have data that goes that far back
    Portfolio.currencies_to_track.each do |name|
      price = Price.where(name: name, timestamp: start_time).take
      raise "Don't have currency data going back to #{start_time} for #{name}" unless price != nil
    end
    holdings = Portfolio.currencies_to_track.map { |name| Holding.new(name)}
    holdings_copy = Portfolio.currencies_to_track.map { |name| Holding.new(name)} # to track non-trading scenario for comparison

    # Show the stats
    bitcoin_price_at_start = Price.where(name: @starting_currency, timestamp: start_time).take.weighted_average
    bitcoin_holdings_at_start = start_usd / bitcoin_price_at_start
    puts "Starting simulation at #{start_time}"
    puts "Bitcoin holdings to start #{bitcoin_holdings_at_start.truncate(3).to_s} BTC worth $#{start_usd} at $#{bitcoin_price_at_start.truncate(3).to_s}/BTC"

    # Prepare the portfolio
    bitcoin_per_holding = bitcoin_holdings_at_start / holdings.count
    holdings.each do |holding|
      buy(holding, bitcoin_per_holding, start_time)
    end
    # Make a backup to compare with doing no trading for the same period
    holdings_copy.each do |holding|
      buy(holding, bitcoin_per_holding, start_time)
    end

    puts "\nPrepared the following portfolio:"
    print_holdings(holdings, start_time)

    # Run the simulation
    puts "Starting simulation (T means traded and _ means nothing happened):"
    current_time = start_time + @trade_frequency
    while current_time <= end_time do
      rebalance(holdings, current_time)
      current_time += @trade_frequency
    end
    end_time = current_time - @trade_frequency
    puts

    # Show the results
    puts "\nPortfolio at the end of the simulation:"
    print_holdings(holdings, end_time)
    bitcoin_price_at_end = Price.where(name: @starting_currency, timestamp: end_time).take.weighted_average
    usd_value_at_end = bitcoin_holdings_at_start * bitcoin_price_at_end

    btc_value_of_copy_portfolio = holdings_value_in_btc(holdings_copy, end_time)
    usd_value_of_copy_portfolio = btc_value_of_copy_portfolio * bitcoin_price_at_end
    puts "Holding the original portfolio and not trading would give you #{btc_value_of_copy_portfolio.truncate(3)} BTC worth $#{usd_value_of_copy_portfolio.truncate(2)}"
    puts "Holding just BTC for the same period would give you #{bitcoin_holdings_at_start.truncate(3)} BTC worth $#{usd_value_at_end.truncate(2)} at $#{bitcoin_price_at_end.truncate(3).to_s}/BTC"
    puts "Simulation completed at #{end_time}"
  end

  def rebalance(holdings, timestamp)
    btc_value = holdings_value_in_btc(holdings, timestamp)

    # return
    # puts "Before"
    # print_holdings(holdings, timestamp)
    # puts

    target_btc_per_holding = btc_value / holdings.count
    target_btc_rebalance_threshhold = 0.1 # if we're out of whack by this much btc sell
    sell = {}
    buy = {}
    total_to_buy = 0.0
    holdings.each do |holding|
      btc_of_holding = holding.quantity * holding.price.weighted_average
      over_target = btc_of_holding - target_btc_per_holding
      if over_target > target_btc_rebalance_threshhold
        sell[holding] = over_target
      elsif over_target < 0
        buy[holding] = -over_target
        total_to_buy += -over_target
      end
    end

    if sell.count > 0 && buy.count > 0
      print "T"
      sell.each do |holding, quanity_in_btc_to_sell|
        @btc_leftover_balance += sell(holding, quanity_in_btc_to_sell, timestamp)
      end

      # Since we may want to buy more than we sold we need a buy adjustment
      buy_adjustment = @btc_leftover_balance.truncate(3) / total_to_buy.truncate(3)

      buy.each do |holding, quanity_in_btc_to_buy|
        quanity_in_btc_to_buy *= buy_adjustment
        if quanity_in_btc_to_buy > @btc_leftover_balance
          quanity_in_btc_to_buy = @btc_leftover_balance
        end
        if quanity_in_btc_to_buy > 0
          buy(holding, quanity_in_btc_to_buy, timestamp)
          @btc_leftover_balance -= quanity_in_btc_to_buy
        end
      end

      @btc_leftover_balance = @btc_leftover_balance.truncate(4)

      if @btc_leftover_balance > 0.01
        raise @btc_leftover_balance.to_s # should never be much leftover
      end
    else
      print "_"
    end

    # puts "After"
    # print_holdings(holdings, timestamp)
    # puts
    # exit
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
    holdings_value_usd = Price.where(name: @starting_currency, timestamp: timestamp).take.weighted_average * holdings_value_btc
    puts "TOTAL_BTC #{holdings_value_btc.truncate(4)} = $#{holdings_value_usd.truncate(2)}\n\n"
  end
end
