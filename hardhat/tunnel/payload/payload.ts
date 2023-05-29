import { ethers } from "hardhat";
import axios, { AxiosResponse } from "axios";
import { ProofUtil } from "./proof_util";
import { ITransactionReceipt } from "./interface";
import ethUtils from "ethereumjs-util";

function getLogIndex_(logEventSig: string, receipt: any) {
  let logIndex = -1;

  switch (logEventSig) {
    case "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef":
    case "0xf94915c6d1fd521cee85359239227480c7e8776d7caf1fc3bacad5c269b66a14":
      logIndex = receipt.logs.findIndex(
        (log: any) =>
          log.topics[0].toLowerCase() === logEventSig.toLowerCase() &&
          log.topics[2].toLowerCase() ===
            "0x0000000000000000000000000000000000000000000000000000000000000000"
      );
      break;

    case "0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62":
    case "0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb":
      logIndex = receipt.logs.findIndex(
        (log: any) =>
          log.topics[0].toLowerCase() === logEventSig.toLowerCase() &&
          log.topics[3].toLowerCase() ===
            "0x0000000000000000000000000000000000000000000000000000000000000000"
      );
      break;

    default:
      logIndex = receipt.logs.findIndex(
        (log: any) => log.topics[0].toLowerCase() === logEventSig.toLowerCase()
      );
  }
  if (logIndex < 0) {
    throw new Error("Log not found in receipt");
  }
  return logIndex;
}

function encodePayload_(
  headerNumber: any,
  buildBlockProof: any,
  blockNumber: any,
  timestamp: any,
  transactionsRoot: any,
  receiptsRoot: any,
  receipt: any,
  receiptParentNodes: any,
  path: any,
  logIndex: any
) {
  return ethUtils.bufferToHex(
    ethUtils.rlp.encode([
      headerNumber,
      buildBlockProof,
      blockNumber,
      timestamp,
      ethUtils.bufferToHex(transactionsRoot),
      ethUtils.bufferToHex(receiptsRoot),
      ethUtils.bufferToHex(receipt),
      ethUtils.bufferToHex(ethUtils.rlp.encode(receiptParentNodes)),
      ethUtils.bufferToHex(Buffer.concat([Buffer.from("00", "hex"), path])),
      logIndex,
    ])
  );
}

function buildBlockProof(
  maticWeb3: any,
  startBlock: number,
  endBlock: number,
  blockNumber: number
) {
  return ProofUtil.getFastMerkleProof(
    maticWeb3,
    blockNumber,
    startBlock,
    endBlock
  ).then((proof) => {
    return ethUtils.bufferToHex(
      Buffer.concat(
        proof.map((p) => {
          return ethUtils.toBuffer(p);
        })
      )
    );
  });
}

export async function buildPayloadForExit(
  burnTxHash: string,
  logEventSig: string,
  isFast: boolean
) {
  const requestConcurrency: number = 0;
  const receipt = await ethers.provider.getTransactionReceipt(burnTxHash);
  const block = await ethers.provider.send("eth_getBlockByNumber", [
    ethers.utils.hexValue(receipt.blockNumber),
    true,
  ]);
  const rootBlockInfo = {
    start: 0,
    end: 1000,
    headerBlockNumber: 500,
  };

  const blockProof: any = await buildBlockProof(
    ethers.provider,
    rootBlockInfo.start,
    rootBlockInfo.end,
    block.number as number
  );
  console.log(blockProof);

  const receiptProof: any = await ProofUtil.getReceiptProof(
    receipt,
    block,
    requestConcurrency
  );

  const logIndex = getLogIndex_(logEventSig, receipt);

  return encodePayload_(
    rootBlockInfo.headerBlockNumber,
    blockProof,
    block.number,
    block.timestamp,
    Buffer.from(block.transactionsRoot.slice(2), "hex"),
    Buffer.from(block.receiptsRoot.slice(2), "hex"),
    ProofUtil.getReceiptBytes(receipt), // rlp encoded
    receiptProof.parentNodes,
    receiptProof.path,
    logIndex
  );
}
