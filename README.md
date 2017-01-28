# Poloniex Altcoin Trading Simulator

This is just a quick hack I threw together to simulate and test a simple rebalancing bot that
starts with a portfolio evenly split among crypto currencies and then rebalances
it every N hours. It uses historical data that it pulls from the poloniex api and 
then compares the results of the trading bot against simply holding the portfolio
of virtual currenceis as well as just holding bitcoin for the same time period. The algorithm 
also takes into account Poloniex trading fees of 0.15% when selling and 0.25% when buying. 

## About the code

This is a Ruby on Rails based project that just grabs all historical data
for the virtual currencies listed in `portfolio.rb` from Poloniex
going back to the beginning of 2016 (see `price_updater.rb`). It also includes a very basic
rebalancing simulation in `rebalance.rb`. I used Rails as the basis just
because it's quick and easy to load up a database with it and then run code against
it.

The code is currently quite ugly as I threw it together one evening
to see if rebalancing a portfolio of crypto currencies outperforms bitcoin itself. My Ruby is
 also pretty rusty. Feel free to help clean it up and send a pull request on github.

It stores the historical data in the `price` table of the `trader_development` database. 
It's currently setup to run against a local MySQL database but if you want to send
me a PR that switches it to a local Sqlite database to make it easier to run that'd be welcome.

## Setup

To setup the project I'm going to assume you already have Ruby, Bundler, and MySQL installed:
```bash
bundle install
rake db:create
rake db:migrate
```

To run the simulation

```bash
rails runner "Scenarios.fetch_data" # fetches historical data
rails runner "Scenarios.run"
```

If you change the portfolio in `portfolio.rb ` you'll need to run `fetch_data` again before
re-running the simulation. In addition to adjusting the `portfolio.rb` also try adjusting
thresholds in `rebalance.rb` that affect how aggressively the rebalance runs. If your tweaks improve the performance of `rebalance.rb` send
a pull request with the changes.

If it's been a few days and you want current data since the last time
you ran it, just re-run `rails runner "Scenarios.fetch_data"` which does an incremental update.

Here's the output of a simulation starting with $5000 split between Factom and MaidSafeCoin

```
> rails runner "Algorithms::RebalanceStandard.new.run"
Starting simulation at 2016-07-13 00:00:00 UTC
Bitcoin holdings to start 7.525 BTC worth $5000.0 at $664.366/BTC

Prepared the following portfolio:
BTC_MAID 35891.88704 3.75357 BTC
BTC_FCT 1763.39186 3.75357 BTC
TOTAL_BTC 7.5071 = $4987.5

Starting simulation (T means traded and _ means nothing happened):
T_______T_T____T______TT__TTTTTTT__T_TT_TTT_T_TTTTTTTTT__TTTTTT_TTTTT_TTT___T_TTT_TT_TT_T_T_T_T_TT_T_TT____TTTTTT____TTT___T__T_T__T______________T____TTTTTTT_TTTTT_____TTTTTTTTT_______T_T___T_TT_T

Portfolio at the end of the simulation:
BTC_MAID 45096.62516 6.30991 BTC
BTC_FCT 1747.53293 6.30925 BTC
TOTAL_BTC 12.6191 = $11346.73

Holding the original portfolio and not trading would give you 11.388 BTC worth $10240.16
Holding just BTC for the same period would give you 7.525 BTC worth $6767.09 at $899.166/BTC
Simulation completed at 2017-01-26 00:00:00 UTC
```
