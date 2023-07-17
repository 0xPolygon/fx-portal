# FX-Portal (Flexible Portal)

FxPortal for Polygon (prev Matic) Chain. No mappings. Seamless communication with Ethereum Network.

### Audits

- [Halborn](audits/Polygon_FX_Portal_Smart_Contract_Security_Audit_Halborn_v1_0.pdf)
- [ChainSecurity](audits/ChainSecurity_Polygon_Fx_Portal_audit.pdf)

### Contents

- [What is FX-Portal](#what-is-fx-portal)
  - [Some usecases](#some-usecases-of-fx-portal)
  - [What about POS-Portal](#what-about-pos-portal)
  - [Can I Build My Own Custom Bridge](#can-i-build-my-own-custom-bridge)
- [What Can I Build With FX-Portal](#what-can-i-build-with-fx-portal)
- [What are fxChild and fxRoot](#what-are-fxchild-and-fxroot)
- [Deployment Addresses](#deployment-addresses)
- [Development](#development)
- [Proof Generation](#proof-generation)

### What is FX-Portal?

**A powerful yet simple implementation of Polygon's [state sync](https://wiki.polygon.technology/docs/category/state-sync/) mechanism. (The Polygon [POS-Portal bridge](https://github.com/maticnetwork/pos-portal/) is also based on it, but relies on a centralized party mapping tokens on one chain to their contract on the other.) There are examples of how to use the bridge in the `contracts/examples` directory. You can use these examples to build your own implementations or own custom bridge.**

In short, this bridge allows arbitrary message bridging without mapping, with built-in support for a number of token standards.

In more detail, FX-Portal makes use of a message passing mechanism built into the Polygon POS chain, leveraging it to pass messages from one chain to another. Using a mechanism for generating deterministic token addresses, this can be used to create asset bridges without the need for a centralized party documenting the relationship between assets on the two chains (commonly referred to as a 'mapping' here).

#### Some usecases of FX-Portal

- [ERC20 token tranfer from Ethereum to Polygon POS without mapping request](https://github.com/0xPolygon/fx-portal/tree/main/contracts/examples/erc20-transfer)
- [Lazy minting of ERC20 tokens on Polygon POS](https://github.com/0xPolygon/fx-portal/tree/main/contracts/examples/mintable-erc20-transfer)
- [State Transfer between Ethereum mainnet and Polygon POS](https://github.com/0xPolygon/fx-portal/tree/main/contracts/examples/state-transfer)

#### What about [POS-Portal](https://github.com/maticnetwork/pos-portal/)?

POS-Portal is another bridge, but it works only for few ERC standards and requires mappings. It is more developer-friendly in some ways, and allows customization without much headache.

While FX-Portal focuses on permissionlessness and flexibility, a developer might have to write more code than POS-Portal. On the other hand, FX-Portal requires no mapping, meaning that there is no need to rely on an authorized party to submit the mapping with FX-Portal.

#### Can I build my own custom bridge?

Yes. You can check docs here: https://wiki.polygon.technology/docs/pos/design/bridge/l1-l2-communication/fx-portal/

### What can I build with FX-Portal?

- Arbitrary state bridge (examples/state-transfer)
- Normal ERC20 bridge (examples/erc2-transfer)
- ERC20 token generator bridge (example/mintable-erc20-transfer)

### What are FxChild and FxRoot?

`FxChild` (`FxChild.sol`) and `FxRoot` (`FxRoot.sol`) are the main contracts on which the bridge works. It calls and passes data to user-defined methods on another chain without needing a mapping. You can deploy your own `FxChild` and `FxRoot`, but there is no need. If you pass the data to the deployed instances of `FxChild` or `FxRoot`, the clients will pick up the data and pass it to the other chain.

### Deployment Addresses

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

### Development

This project can be compiled and tested with Hardhat and Foundry. Hardhat unit tests are located in [/hardhat](/hardhat) and Foundry unit + invariant tests can be found in the [/test](/test) directory.

- Setup: `yarn install` and/or `forge install`
- Compile: `yarn build` and/or `forge build`
- Test: `yarn test` and/or `forge test -vvv`
- Coverage: `yarn coverage`
- Lint: `yarn lint`, `yarn prettier:write`

#### Proof Generation

A common question is how to generate proofs for the bridge. We'll explain what that means, and then list solutions.

To withdraw tokens on the root chain, first we call the relevant `withdraw()` method the child tunnel contract (which burn the respective tokens on child); and we use this transaction hash to generate proof of inclusion which acts as the argument to receiveMessage() in the respective root tunnel contract. Please see [here](https://wiki.polygon.technology/docs/pos/design/bridge/l1-l2-communication/fx-portal/#withdraw-tokens-on-the-root-chain).

To generate the proof, you can either use the [proof generation API](https://proof-generator.polygon.technology/api/v1/matic/exit-payload/%7BburnTxHash%7D?eventSignature=%7BeventSignature%7D) hosted by Polygon or you can also spin up your own proof generation API by following the instructions [here](https://github.com/maticnetwork/proof-generation-api).

The test suite also replicates proof generation (located at [hardhat/tunnel/payload](hardhat/tunnel/payload)), the following _hardhat task_ can help generating the proof for custom chains.

**Usage**: `npx hardhat exit-proof --help`

```
hardhat [GLOBAL OPTIONS] exit-proof [--sig <STRING>] --tx <STRING>

OPTIONS:

--sig log event hex signature (defaults to 0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036 for `MessageSent(bytes)`)
--tx burn transaction hash

exit-proof: Generates exit proof for the given burn transaction hash
```

**Example**: `npx hardhat exit-proof --network polygon --tx 0x1cfc2658719e6d1753e091ce4515507711fe649269e75023c0f1123cd6e37c1a`

```
➜ npx hardhat exit-proof --network polygon --tx 0x1cfc2658719e6d1753e091ce4515507711fe649269e75023c0f1123cd6e37c1a
0xf909988201f4a0c8e08649aed43a802751213ece497804bd3acaee5d237326e0839c413b0920408402ae4af38464ae328da0d4ab5e911c81df7bfdc20e816de49c97f4808fcb1bcad63e328d0bca15a099e9a05e130cf2c4fb5778776309c95af5ca17ecbb47f6d3fc81c09bf110786269e2a6b903e702f903e3018355f7a2b9010000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000001000000008000000000000000000000000000000000000000000000000008000000800008000000000000000100000000000000000000020000000000000000000800000000000040000080000018000004000040000000040000000000000000000000020000000000000000000000000000200000000000001000000000000000000000000000000000000000000000004000000002000000000401000000000000000000000000000000120020000020000000100000000000000000000000000000001000000000000000000000100000f902d8f89b94aaf7701db5f8704450c6db28db99ea0a927e76adf863a0ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3efa000000000000000000000000086eb278eeed79a44b5e3c83a012b96aa450912aba00000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000087de5c5bd1dccf709cf8f994d531cf2142d9b9dc8b077df3c4e93b46e7cf879ae1a08c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036b8c000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000080000000000000000000000000922ac473a3cc241fd3a0049ed14536452d58d73c000000000000000000000000aaf7701db5f8704450c6db28db99ea0a927e76ad00000000000000000000000086eb278eeed79a44b5e3c83a012b96aa450912ab000000000000000000000000000000000000000000000087de5c5bd1dccf709cf9013d940000000000000000000000000000000000001010f884a04dfe1bbbcf077ddc3e01291eea2d5c70c2b422b415d95645b9adcfd678cb1d63a00000000000000000000000000000000000000000000000000000000000001010a000000000000000000000000086eb278eeed79a44b5e3c83a012b96aa450912aba00000000000000000000000009ead03f7136fc6b4bdb0780b00a1c14ae5a8b6d0b8a00000000000000000000000000000000000000000000000000004f478e611780000000000000000000000000000000000000000000000000000e5dc5800087ecc000000000000000000000000000000000000000000000377f97e15a609a765bd00000000000000000000000000000000000000000000000000e0e7df19f706cc000000000000000000000000000000000000000000000377f9830a1eefb8ddbdb90537f90534f891a02dad7ffa3e44092c885002e5d2a48f58793d842ccc99aeccdb23c0094ac32c7da04696502faee79a586bd17877e2d1a66dd8dc0af8381fc488017c091e09dd3024a0360e2917de87f795b9350a7c29785a74da6582a4aeac0f20890cb0ac9820178c8080808080a0e2c9ed1fad4ea1a707e92bd2823e14a47f3cd5ff74258255c5b4961656bb4d098080808080808080f8b1a0299225ca484915f0ae642515e04aa9ddb2a86388f4404760715fa012f910ad28a0262c2288a6a1205fb045b10c14a9cfbac0196f9bb09b49e6523d90b4b8837cf5a01f727d97002d78492609ee434fc6daf0ab9f8347c393f488a178a59ad79775b7a0aa49afed4d9c80d7146bd606a9b111859a7b2b163e99b6320913a0977f1716aba026620528634fdd31f0bcbe97eef787f9244cf317928675c6da146d416ec282a4808080808080808080808080f903eb20b903e702f903e3018355f7a2b9010000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000001000000008000000000000000000000000000000000000000000000000008000000800008000000000000000100000000000000000000020000000000000000000800000000000040000080000018000004000040000000040000000000000000000000020000000000000000000000000000200000000000001000000000000000000000000000000000000000000000004000000002000000000401000000000000000000000000000000120020000020000000100000000000000000000000000000001000000000000000000000100000f902d8f89b94aaf7701db5f8704450c6db28db99ea0a927e76adf863a0ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3efa000000000000000000000000086eb278eeed79a44b5e3c83a012b96aa450912aba00000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000087de5c5bd1dccf709cf8f994d531cf2142d9b9dc8b077df3c4e93b46e7cf879ae1a08c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036b8c000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000080000000000000000000000000922ac473a3cc241fd3a0049ed14536452d58d73c000000000000000000000000aaf7701db5f8704450c6db28db99ea0a927e76ad00000000000000000000000086eb278eeed79a44b5e3c83a012b96aa450912ab000000000000000000000000000000000000000000000087de5c5bd1dccf709cf9013d940000000000000000000000000000000000001010f884a04dfe1bbbcf077ddc3e01291eea2d5c70c2b422b415d95645b9adcfd678cb1d63a00000000000000000000000000000000000000000000000000000000000001010a000000000000000000000000086eb278eeed79a44b5e3c83a012b96aa450912aba00000000000000000000000009ead03f7136fc6b4bdb0780b00a1c14ae5a8b6d0b8a00000000000000000000000000000000000000000000000000004f478e611780000000000000000000000000000000000000000000000000000e5dc5800087ecc000000000000000000000000000000000000000000000377f97e15a609a765bd00000000000000000000000000000000000000000000000000e0e7df19f706cc000000000000000000000000000000000000000000000377f9830a1eefb8ddbd82002201
```
