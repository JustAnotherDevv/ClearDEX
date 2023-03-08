# ClearDEX orderbook
Modern DEX with orderbook implemented in Clarity. Created for Building on Bitcoin Hackathon 2023.

## Instructions

⚫Run `clarinet check` to check smart contracts for error and warnings

⚫Run `clarinet console` for local Stacks environment where you can call smart contract functions

⚫Run `clarinet test` to execute tests for the smart contracts


## About the project

 This DEX orderbook will allow users to place buy and sell orders for various cryptocurrencies in a decentralized manner, without the need for a central authority. Currently for demonstration purposes it's only limited to trades between STX and custom clear token but it could be deployed with other tokens available on the Stacks.

It's important to emphasize that it uses orderbook instead of typical AMM to facilitate token swaps.

Using orderbook has many benefits over AMM-based one such as:

⚫Users can take advantage of limit orders

⚫Users benefit of lower slippage and lower trading fees

⚫User can see the specific prices points at which liquidity is most concentrated, which might benefit their trading strategy


## Accomplishments

I am happy that I was able to finish my MVP within just a few days. Now this Open-Source proof of concept could become backbone of bigger project or could serve as learning material for other Clarity developers.


## What's next for ClearDEX

In the future I will work on adding more features to make this project more complete. Such as filling bigger order at market price that would complete multiple buy / sell orders from different users etc.
