const ContractFactory = require("@ethersproject/contracts").ContractFactory;
const Contract = require("@ethersproject/contracts").Contract;
const expect = require("chai").expect;
const providers = require("ethers").providers;
const Wallet = require("ethers").Wallet;
const ethers = require("hardhat").ethers;
// const run = require("hardhat").run;
const FxStateRootTunnel = require("../artifacts/contracts/examples/state-transfer/FxStateRootTunnel.sol/FxStateRootTunnel.json");
const FxStateChildTunnel = require("../artifacts/contracts/examples/state-transfer/FxStateChildTunnel.sol/FxStateChildTunnel.json");

describe("FxState Tunnel Deployment", function () {
  const GOERLI_CHECKPOINT_MANAGER = `0x2890bA17EfE978480615e330ecB65333b880928e`;
  const GOERLI_FX_ROOT = `0x3d1d3E34f7fB6D26245E6640E1c50710eFFf15bA`;
  const MUMBAI_FX_CHILD = `0xCf73231F28B7331BBe3124B907840A94851f9f11`;

  const ACCOUNT_KEY_PRIV_GOERLI = `0x${process.env.ACCOUNT_KEY_PRIV_GOERLI}`;
  const ACCOUNT_KEY_PRIV_MUMBAI = `0x${process.env.ACCOUNT_KEY_PRIV_MUMBAI}`;
  const JSON_RPC_GOERLI = `${process.env.NETWORK_GOERLI}`;
  const JSON_RPC_POLYGON_MUMBAI = `${process.env.NETWORK_POLYGON_MUMBAI}`;
  let providerGoerli;
  let providerMumbai;
  let walletGoerli;
  let walletMumbai;

  let rootTunnel;
  let rootTunnelAddress;
  let childTunnel;
  let childTunnelAddress;

  let latestBlockNumber;

  before(async function () {
    providerGoerli = new providers.JsonRpcProvider(JSON_RPC_GOERLI);
    providerMumbai = new providers.JsonRpcProvider(JSON_RPC_POLYGON_MUMBAI);
    walletGoerli = new Wallet(ACCOUNT_KEY_PRIV_GOERLI, providerGoerli);
    walletMumbai = new Wallet(ACCOUNT_KEY_PRIV_MUMBAI, providerMumbai);
  });

  describe("Chain Checks", function () {
    it("Should have gotten the latest block number.", async function () {
      latestBlockNumber = await providerGoerli.getBlockNumber();
      console.log("Latest block number: ", latestBlockNumber);
      expect(latestBlockNumber).not.to.be.null;
    });
  });

  describe("Tunnel Deployment", function () {
    it("Should have deployed the Root Tunnel contract on Ethereum", async function () {
      const rootTunnelFactory = new ContractFactory(
        FxStateRootTunnel.abi,
        FxStateRootTunnel.bytecode,
        walletGoerli
      );
      rootTunnel = await rootTunnelFactory.deploy(
        GOERLI_CHECKPOINT_MANAGER,
        GOERLI_FX_ROOT
      );
      rootTunnelAddress = rootTunnel.address;
      console.log("Deployed Root Tunnel Contract: ", rootTunnelAddress);
      console.log("Root Tunnel Data: ", await rootTunnel.latestData());

      expect(rootTunnelAddress).not.to.be.null;
    });

    it("Should have deployed the Child Tunnel contract on Polygon", async function () {
      const childTunnelFactory = new ContractFactory(
        FxStateChildTunnel.abi,
        FxStateChildTunnel.bytecode,
        walletMumbai
      );
      childTunnel = await childTunnelFactory.deploy(MUMBAI_FX_CHILD);
      childTunnelAddress = childTunnel.address;
      console.log("Deployed Child Tunnel Contract: ", childTunnelAddress);
      console.log("Child Tunnel Data: ", await childTunnel.latestData());

      expect(childTunnelAddress).not.to.be.null;
    });
  });

  describe("Tunnel Setup", function () {
    it("Should have set Child Tunnel address on Root Tunnel contract", async function () {
      const res = await rootTunnel.setFxChildTunnel(childTunnelAddress);

      // NOTE: Wait for the transaction to be validated.
      await res.wait();
      const childTunnelCheck = await rootTunnel.fxChildTunnel();
      console.log(
        "Root Tunnel Set Child Tunnel address check: ",
        childTunnelCheck
      );

      expect(childTunnelCheck).equals(childTunnelAddress);
    });

    it("Should have set Root Tunnel address on Child Tunnel contract", async function () {
      const res = await childTunnel.setFxRootTunnel(rootTunnelAddress);

      // NOTE: Wait for the transaction to be validated.
      await res.wait();
      const rootTunnelCheck = await childTunnel.fxRootTunnel();
      console.log(
        "Child Tunnel Set Root Tunnel address check: ",
        rootTunnelCheck
      );

      expect(rootTunnelCheck).equals(rootTunnelAddress);
    });
  });

  describe("Send Messages", function () {
    const timestamp = Date.now();
    console.log("Timestamp: ", timestamp);

    it("Root data should not immediately change after child sends a message to root", async function () {
      // Record the latest root data as a reference point before sending the message.
      const rootDataStart = await rootTunnel.latestData();
      console.log("Starting Root Tunnel Data: ", rootDataStart);
      const res = await childTunnel.sendMessageToRoot(
        ethers.utils.formatBytes32String(`Hello Root! (${timestamp})`)
      );

      // NOTE: Wait for the transaction to be validated before completing the test.
      await res.wait();

      // The ending root tunnel data should be the same as the starting root tunnel data.
      const rootDataEnd = await rootTunnel.latestData();
      console.log("Ending Root Tunnel Data: ", rootDataEnd);
      expect(rootDataStart).equals(rootDataEnd);
    });

    it("Child data should not immediately change after root sends a message to child", async function () {
      // Record the latest child data as a reference point before sending the message.
      const childDataStart = await childTunnel.latestData();
      console.log("Starting Child Tunnel Data: ", childDataStart);
      const res = await rootTunnel.sendMessageToChild(
        ethers.utils.formatBytes32String(`Hello Child! (${timestamp})`)
      );

      // NOTE: Wait for the transaction to be validated before completing the test.
      await res.wait();

      // The ending child tunnel data should be the same as the starting child tunnel data.
      const childDataEnd = await childTunnel.latestData();
      console.log("Ending Child Tunnel Data: ", childDataEnd);
      expect(childDataStart).equals(childDataEnd);
    });
  });

  // NOTE: The cross-chain transaction might take a while to be validated.
  // Watch Event Logs here: https://mumbai.polygonscan.com/address/0xcf73231f28b7331bbe3124b907840a94851f9f11#events
  // Watch for transactions here: https://mumbai.polygonscan.com/address/0x0000000000000000000000000000000000000000

  // describe("Verify Contracts", function () {
  //   it("Should have verified the root contract.", async function () {
  //     let res = await run(`verify:verify`, {
  //       address: rootTunnelAddress,
  //       constructorArguments: [GOERLI_CHECKPOINT_MANAGER, GOERLI_FX_ROOT],
  //       network: "goerli",
  //     });
  //     console.log("Root contract verification result: ", res);

  //     expect(1).equals(1);
  //   });
  // });
});
