# fx-portal(Flexible portal)

FxPortal for Polygon(prev Matic)Chain. No mapping. Seamless communication with Ethereum Network.

### Audits
- [Halborn](audits/Polygon_FX_Portal_Smart_Contract_Security_Audit_Halborn_v1_0.pdf)
- [ChainSecurity](audits/ChainSecurity_Polygon_Fx_Portal_audit.pdf)

### What is Fx bridge (fx-portal)?

**It is a powerful yet simple implementation Polygon [state sync](https://docs.matic.network/docs/contribute/state-sync) mechanism. Polygon PoS bridge is based on it. The code in the `examples` folder are examples of the usage of this methodology. You can use these examples to build your own implementations or own custom bridge.**

In short, it's Meta bridge. This bridge allows any state-syncs without mapping.

#### Some use-cases of Fx-portal

- [ERC20 token tranfer from Ethereum to Polygon POS without mapping request](https://github.com/0xPolygon/fx-portal/tree/main/contracts/examples/erc20-transfer)
- [Lazy minting of ERC20 tokens on Polygon POS](https://github.com/0xPolygon/fx-portal/tree/main/contracts/examples/mintable-erc20-transfer)
- [State Transfer between Ethereum mainnet and Polygon POS](https://github.com/0xPolygon/fx-portal/tree/main/contracts/examples/state-transfer)

**What about [PoS portal](https://docs.matic.network/docs/develop/ethereum-matic/pos/getting-started)?**

PoS Portal is another bridge, but it works only for few ERC standards and requires mappings. It is more developer-friendly, allows customization without much headache.

While Fx-portal focuses on permissionless-ness and flexibility, a developer might have to write more code but more customizable than PoS Portal. It requires no mapping.

**Can I build my bridge?**

Yes. You can check docs here: https://wiki.polygon.technology/docs/develop/l1-l2-communication/ethereum-to-matic/
https://wiki.polygon.technology/docs/develop/l1-l2-communication/matic-to-ethereum/

### What are FxChild and FxRoot?

`FxChild` (FxChild.sol) and `FxRoot` (FxRoot.sol) are main contracts on which mapping-less bridge works. It calls and passes data to user-defined methods on another chain without mapping.

**Mumbai**

| Contract                                                                                                                | Deployed address                             |
| :---------------------------------------------------------------------------------------------------------------------- | :------------------------------------------- |
| [FxRoot (Goerli)](https://goerli.etherscan.io/address/0x3d1d3E34f7fB6D26245E6640E1c50710eFFf15bA#code)                  | `0x3d1d3E34f7fB6D26245E6640E1c50710eFFf15bA` |
| [FxChild (Mumbai)](https://explorer-mumbai.maticvigil.com/address/0xCf73231F28B7331BBe3124B907840A94851f9f11/contracts) | `0xCf73231F28B7331BBe3124B907840A94851f9f11` |

**Mainnet**

| Contract                                                                                                                         | Deployed address                             |
| :------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------- |
| [FxRoot (Ethereum Mainnet)](https://etherscan.io/address/0xfe5e5d361b2ad62c541bab87c45a0b9b018389a2#code)                        | `0xfe5e5D361b2ad62c541bAb87C45a0B9B018389a2` |
| [FxChild (Matic Mainnnet)](https://explorer-mainnet.maticvigil.com/address/0x8397259c983751DAf40400790063935a11afa28a/contracts) | `0x8397259c983751DAf40400790063935a11afa28a` |

You can deploy your own `FxChild` and `FxRoot`, but no need. Except you want to have some fun and have extra ETH to throw away.

### What can I build with it?

- Arbitrary state bridge (examples/state-transfer)
- Normal ERC20 bridge (examples/erc2-transfer)
- ERC20 token generator bridge (example/mintable-erc20-transfer)
