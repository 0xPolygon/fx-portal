# fx-portal-test

フォーク元: https://github.com/fx-portal/contracts

## 手順

### 1. TEST トークンをデプロイ(Goerli)

```sh
npx hardhat run script/1-deploy-test-token-ethereum.js --network goerli
```

完了したら.env の ERC20_ROOT_TOKEN にアドレス記入

### 2. RootTunnel をデプロイ(Goerli)

```sh
npx hardhat run script/2-deploy-root-tunnel-ethereum.js --network goerli
```

完了したら.env の FX_ERC20_ROOT_TUNNEL にアドレス記入

### 3. ChildTunnel をデプロイ(Mumbai)

```sh
npx hardhat run script/3-deploy-child-tunnel-polygon.js --network mumbai
```

完了したら.env の FX_ERC20_CHILD_TUNNEL にアドレス記入

### 4. デポジット(Goerli)

```sh
npx hardhat run scripts/4-deposit-test-token-ethereum.js --network goerli
```

30 分ほど待つと Mumbai 側にブリッジされる。

# fx-portal(Flexible portal)

FxPortal for Polygon(prev Matic)Chain. No mapping. Seamless communication with Ethereum Network.

Audit - [Fx-Portal Contracts Audit by Halborn](<https://github.com/fx-portal/contracts/blob/main/Polygon_FX_Portal_Smart_Contract_Security_Audit_Halborn_v1_0%20(1).pdf>)

### What is Fx bridge (fx-portal)?

**It is a powerful yet simple implementation Polygon [state sync](https://docs.matic.network/docs/contribute/state-sync) mechanism. Polygon PoS bridge is based on it. The code in the `examples` folder are examples of the usage of this methodology. You can use these examples to build your own implementations or own custom bridge.**

In short, it's Meta bridge. This bridge allows any state-syncs without mapping.

#### Some use-cases of Fx-portal

- [ERC20 token tranfer from Ethereum to Matic-Chain without mapping request](https://github.com/jdkanani/fx-portal/tree/main/contracts/examples/erc20-transfer)
- [Lazy minting of ERC20 tokens on MaticChain](https://github.com/jdkanani/fx-portal/tree/main/contracts/examples/mintable-erc20-transfer)
- [State Transfer between Ethereum-Matic](https://github.com/jdkanani/fx-portal/tree/main/contracts/examples/state-transfer)

**What about [PoS portal](https://docs.matic.network/docs/develop/ethereum-matic/pos/getting-started)?**

PoS Portal is another bridge, but it works only for few ERC standards and requires mappings. It is more developer-friendly, allows customization without much headache.

While Fx-portal focuses on permissionless-ness and flexibility, a developer might have to write more code but more customizable than PoS Portal. It requires no mapping.

**Can I build my bridge?**

Yes. You can check docs here: https://docs.matic.network/docs/develop/l1-l2-communication/ethereum-to-matic
https://docs.matic.network/docs/develop/l1-l2-communication/matic-to-ethereum

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
