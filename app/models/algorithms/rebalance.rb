class Algorithms::Rebalance

  def initialize
    @btc_leftover_balance = 0.0 # if there's a little btc leftover after buying store it here
    @btc_rebalance_threshhold = 0.1 # if a holding is over-allocated by this much harvest the gains
  end

  def run(simulator, holdings, timestamp)
    btc_value = simulator.holdings_value_in_btc(holdings, timestamp)
    target_btc_per_holding = btc_value / holdings.count

    # Check each holding to see if we need to buy it or sell it
    sell = {}
    buy = {}
    total_to_buy = 0.0
    holdings.each do |holding|
      btc_of_holding = holding.quantity * holding.price.weighted_average
      over_target = btc_of_holding - target_btc_per_holding
      if over_target > @btc_rebalance_threshhold
        sell[holding] = over_target
      elsif over_target < 0
        buy[holding] = -over_target
        total_to_buy += -over_target
      end
    end

    # Only sell winners if we have losers to buy
    if sell.count > 0 && buy.count > 0
      print "T"
      sell.each do |holding, quanity_in_btc_to_sell|
        @btc_leftover_balance += simulator.sell(holding, quanity_in_btc_to_sell, timestamp)
      end

      # Since we may want to buy more than we sold we need a buy adjustment
      buy_adjustment = @btc_leftover_balance.truncate(3) / total_to_buy.truncate(3)

      buy.each do |holding, quanity_in_btc_to_buy|
        quanity_in_btc_to_buy *= buy_adjustment
        if quanity_in_btc_to_buy > @btc_leftover_balance
          quanity_in_btc_to_buy = @btc_leftover_balance
        end
        if quanity_in_btc_to_buy > 0
          simulator.buy(holding, quanity_in_btc_to_buy, timestamp)
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

  end

end