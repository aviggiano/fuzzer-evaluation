# fuzzer-evaluation
Evaluating fuzzer effectiveness

## Usage

Test against the default codebase ("ground truth")

```
make test
```

Test against mutated code (injected bugs)

```
make evaluate seed=<seed>
```

## Properties

### uniswap-v2

| Property | Description |
| --- | --- |
| P-01 | Adding liquidity increases k |
| P-02 | Adding liquidity increases the total supply of LP tokens |
| P-03 | Adding liquidity increases reserves of both tokens |
| P-04 | Adding liquidity increases the user's LP balance |
| P-05 | Adding liquidity decreases the user's token balances |
| P-06 | Adding liquidity does not decrease the `feeTo` LP balance |
| P-07 | Adding liquidity for the first time should mint LP tokens equals to the square root of the product of the token amounts minus a minimum liquidity constant |
| P-08 | Adding liquidity should not change anything if it fails |
| P-09 | Adding liquidity should not fail if the provided amounts are withing the valid range of `uint112`, would mint positive liquidity and are above the minimum initial liquidity check when minting for the first time  |
| P-10 | Removing liquidity decreases k |
| P-11 | Removing liquidity decreases the total supply of LP tokens if fee is off |
| P-12 | Removing liquidity decreases reserves of both tokens |
| P-13 | Removing liquidity decreases the user's LP balance |
| P-14 | Removing liquidity increases the user's token balances |
| P-15 | Removing liquidity does not decrease the `feeTo` LP balance |
| P-16 | Removing liquidity should not change anything if it fails |
| P-17 | Removing liquidity should not fail if the returned amounts to the user are greater than zero |
| P-18 | Swapping does not decrease k |
| P-19 | Swapping increases the sender's tokenOut balance |
| P-20 | Swapping decreases the sender's tokenIn balance by swapAmountIn |
| P-21 | Swapping does not decrease the `feeTo` LP balance |
| P-22 | Swapping should not fail if there's enough liquidity, if the output would be positive and if the input would not overflow the valid range of `uint112` |

## References

- [Evaluating Fuzz Testing](https://cseweb.ucsd.edu/~dstefan/cse227-spring20/papers/klees:evaluating.pdf)
- [Echidna Streaming Workshop](https://github.com/crytic/echidna-streaming-series)
- [Fuzzy DeFi: Pre-built security properties for commonly forked DeFi protocols](https://github.com/0xNazgul/fuzzydefi)