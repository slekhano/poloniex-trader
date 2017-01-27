class Portfolio
  cattr_accessor :currencies_to_track
  @@currencies_to_track = ['BTC_XRP', 'BTC_MAID', 'BTC_XMR', 'BTC_LTC',
                           'BTC_LSK', 'BTC_ETH', 'BTC_DOGE', 'BTC_DASH',
                           'BTC_SC', 'BTC_FCT']

end