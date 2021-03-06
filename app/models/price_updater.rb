class PriceUpdater

  def self.fetch_all
    # See all currencies https://poloniex.com/public?command=returnTicker
    currencies = Portfolio.currencies_to_track
    # We also need to track the reference currency
    currencies = currencies + [Portfolio.reference_currency] unless currencies.include? Portfolio.reference_currency
    currencies.each do |name|
      fetch_and_update(name)
    end
  end

  def self.fetch_and_update(name)
    raise "Name required (e.g. BTC_ETH)" if name.blank?
    start = 1451606400 # Jan 1 2016 00:00:00
    interval = 14400
    latest_timestamp = Price.where(name: name).maximum(:timestamp)
    if latest_timestamp != nil
      start = latest_timestamp.to_time.to_i + interval
    end
    response = HTTParty.get 'https://poloniex.com/public', {query: {command: 'returnChartData', currencyPair: name, start: start, end: 9999999999, period: interval}, format: :json}
    puts "#{name}: #{response.code} #{response.request.last_uri.to_s}"
    if response.code == 200
      count = 0
      response.each do |price_data|
        next unless price_data['date'] > 0
        print '.'
        price = Price.new({
                              name: name,
                              timestamp: Time.at(price_data['date']).to_datetime,
                              high: price_data['high'],
                              low: price_data['low'],
                              open: price_data['open'],
                              close: price_data['close'],
                              volume: price_data['volume'],
                              quote_volume: price_data['quoteVolume'],
                              weighted_average: price_data['weightedAverage']
                          })
        price.save!
        count += 1
      end
      puts "#{count > 0 ? "\n" : ""}#{name}: Created #{count} records"
    else
      raise response.to_s
    end
  end

end