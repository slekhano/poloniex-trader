class Scenarios

  def self.fetch_data
    PriceUpdater.fetch_all
  end

  def self.run
    returns = {} # track the returns of each approach
    simulator = Simulator.new(Portfolio.currencies_to_track)

    # First let's just hold bitcoin and see how that does
    returns["Hold Bitcoin"] = simulator.run_holding_btc

    # Hold the portfolio from Portfolio.currencies_to_track and don't trade
    buy_and_hold = Algorithms::Hold.new
    returns["Hold Portolio"] = simulator.run(buy_and_hold)

    # Run the rebalance algorithm rebalancing the portfolio every 4 hours
    rebalance = Algorithms::Rebalance.new
    returns["Rebalance Portfolio"] = simulator.run(rebalance)

    puts "Simulation Summary\n------------------"
    returns.each do |name, roi|
      puts "#{name}: #{(roi * 100).truncate(2)}%"
    end
  end

end