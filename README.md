# README

At the moment this rails project just grabs all historical data
for the virtual currencies listed in price_updater.rb from Poloniex
going back to the beginning of 2016. 

It stores the data in the `price` table of the `trader_development` database.
  
To populate the database

```bash
rake db:create
rails runner "PriceUpdater.fetch_all"
```

To do an incremental update to get any new data since the `PriceUpdater` last
ran just re-run `rails runner "PriceUpdater.fetch_all"`

