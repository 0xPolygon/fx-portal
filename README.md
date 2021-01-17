# fx-portal
FxPortal for Matic chain. No mapping. Seamless.

**Warning:** Code is not audited.

### What is Fx bridge (fx-portal)?

It's Meta bridge. This bridge allows any type of state sync without mapping.

**What about PoS portal?**

PoS Portal is another bridge but it works only for few ERC standards and requires mappings. It is more developer friendly, allows customization without much headache. 

While Fx-portal focuses on permissionless-ness and flexibility. A deverloper might have to write more code but more customizatable than PoS Portal. Requires no mapping.

**Can I built my own bridge?**

Yes. You can check docs here: https://docs.matic.network/docs/develop/l1-l2-communication/ethereum-to-matic and https://docs.matic.network/docs/develop/l1-l2-communication/matic-to-ethereum 

### What is FxChild and FxRoot?

`FxChild` (FxChild.sol)  and `FxRoot` (FxRoot.sol) are main contracts on which mapping-less bridge works. It calls and passes data to user-defined methods on another chain without mapping.

**Mumbai**

| Contract | Deployed address  |
| :----- | :- |
| [FxRoot (Goerli)](https://goerli.etherscan.io/address/0x3d1d3E34f7fB6D26245E6640E1c50710eFFf15bA#code) | `0x3d1d3E34f7fB6D26245E6640E1c50710eFFf15bA` |
| [FxChild (Mumbai)](https://explorer-mumbai.maticvigil.com/address/0xCf73231F28B7331BBe3124B907840A94851f9f11/contracts) | `0xCf73231F28B7331BBe3124B907840A94851f9f11`|

**Mainnet**


| Contract | Deployed address  |
| :----- | :- |
| [FxRoot (Ethereum Mainnet)](https://etherscan.io/address/0xfe5e5d361b2ad62c541bab87c45a0b9b018389a2#code) | `0xfe5e5D361b2ad62c541bAb87C45a0B9B018389a2` |
| [FxChild (Matic Mainnnet)](https://explorer-mainnet.maticvigil.com/address/0x8397259c983751DAf40400790063935a11afa28a/contracts) | `0x8397259c983751DAf40400790063935a11afa28a`|


You can deploy your own `FxChild` and `FxRoot`. But no need, except you just want to have some fun and extra ETH to throw away.

### What can I build with it?

* Arbitrary state bridge (examples/state-transfer)
* Normal ERC20 bridge (examples/erc2-transfer)
* ERC20 token generator bridge (example/mintable-erc20-transfer)

