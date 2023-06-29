# fuzzer-evaluation
Evaluating fuzzer effectiveness through mutation testing

## Setup

1. Install dependencies
2. Follow installation instructions on all submodules

## Properties

### uniswap-v2

| Property | Description |
| --- | --- |
| P-01 | Adding liquidity increases K |
| P-02 | Adding liquidity increases the total supply of LP tokens |
| P-03 | Adding liquidity increases reserves of both tokens |
| P-04 | Adding liquidity increases the users' LP balance |
| P-05 | Adding liquidity should not fail if the provided amounts are withing the valid range of `uint112`, would not mint 0 liquidity and are above the minimum initial liquidity check when minting for the first time  |
| P-05 | Removing liquidity decreases K |
| P-06 | Removing liquidity decreases the total supply of LP tokens |
| P-07 | Removing liquidity decreases reserves of both tokens |
| P-08 | Removing liquidity decreases the users' LP balance |
| P-09 | Removing liquidity should not fail if the returned amounts to the user are greater than zero |
| P-10 | Swapping does not decrease K |
| P-11 | Swapping increases the sender's tokenOut balance |
| P-12 | Swapping decreases the sender's tokenIn balance |
| P-13 | Swapping is "path independent" except for fees |
| P-14 | Swapping does not decrease the `feeTo` LP balance |
| P-15 | The balances of the two tokens should be in the valid range of `uint112` |

## References

- [Evaluating Fuzz Testing](https://cseweb.ucsd.edu/~dstefan/cse227-spring20/papers/klees:evaluating.pdf)
- [Fuzzy DeFi: Pre-built security properties for commonly forked DeFi protocols](https://github.com/0xNazgul/fuzzydefi)
- [Echidna Streaming Workshop](https://github.com/crytic/echidna-streaming-series)