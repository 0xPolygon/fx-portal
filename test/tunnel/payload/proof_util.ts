// import { BaseWeb3Client } from "../abstracts";
// import { MerkleTree } from "./merkle_tree";
import { ethers } from 'hardhat';
import ethUtils from "ethereumjs-util";
// import { ITransactionReceipt, IBlock, IBlockWithTransaction } from "../interfaces";
import { mapPromise } from "./map_promise";
const TRIE = require('merkle-patricia-tree');
const rlp = ethUtils.rlp;
import {Block} from '@ethereumjs/block';
import { Converter } from "./converter";
import { promiseResolve } from "./promise_resolve";
import { ITransactionReceipt, IBlockWithTransaction } from "./interface";

export class ProofUtil {
    static getReceiptProof(receipt: any, block: any, requestConcurrency = Infinity, receiptsVal?: ITransactionReceipt[]) {
        const stateSyncTxHash = ethUtils.bufferToHex(ProofUtil.getStateSyncTxHash(block));
        const receiptsTrie = new TRIE();
        let receiptPromise: Promise<ITransactionReceipt[]>;
        if (!receiptsVal) {
            let receiptPromises: any = [];
            block.transactions.forEach((tx: any)=> {
                if (tx.transactionHash === stateSyncTxHash) {
                    // ignore if tx hash is bor state-sync tx
                    return;
                }
                receiptPromises.push(
                    ethers.provider.getTransactionReceipt(tx.transactionHash)
                );
            });
            receiptPromise = mapPromise(
                receiptPromises,
                (val:any) => {
                    return val;
                },
                {
                    concurrency: requestConcurrency,
                }
            );
        }
        else {
            receiptPromise = promiseResolve(receiptsVal);
        }

        return receiptPromise.then(receipts => {
            return Promise.all(
                receipts.map(siblingReceipt => {
                    const path = rlp.encode(siblingReceipt.transactionIndex);
                    const rawReceipt = ProofUtil.getReceiptBytes(siblingReceipt);
                    return new Promise((resolve, reject) => {
                        receiptsTrie.put(path, rawReceipt, (err: any) => {
                            if (err) {
                                reject(err);
                            } else {
                                resolve({});
                            }
                        });
                    });
                })
            );
        }).then(_ => {
            // promise
            return new Promise((resolve, reject) => {
                receiptsTrie.findPath(rlp.encode(receipt.transactionIndex), (err: any, rawReceiptNode: any, reminder: any, stack: any) => {
                    if (err) {
                        return reject(err);
                    }

                    if (reminder.length > 0) {
                        return reject(new Error('Node does not contain the key'));
                    }

                    const prf = {
                        blockHash: ethUtils.toBuffer(receipt.blockHash),
                        parentNodes: stack.map((s: any) => s.raw),
                        root: ProofUtil.getRawHeader(block).receiptTrie,
                        path: rlp.encode(receipt.transactionIndex),
                        value: ProofUtil.isTypedReceipt(receipt) ? rawReceiptNode.value : rlp.decode(rawReceiptNode.value)
                    };
                    resolve(prf);
                });
            });
        });
    }

    static isTypedReceipt(receipt: ITransactionReceipt) {
        const hexType = Converter.toHex(receipt.type);
        return receipt.status != null && hexType !== "0x0" && hexType !== "0x";
    }

    // getStateSyncTxHash returns block's tx hash for state-sync receipt
    // Bor blockchain includes extra receipt/tx for state-sync logs,
    // but it is not included in transactionRoot or receiptRoot.
    // So, while calculating proof, we have to exclude them.
    //
    // This is derived from block's hash and number
    // state-sync tx hash = keccak256("matic-bor-receipt-" + block.number + block.hash)
    static getStateSyncTxHash(block: any): Buffer {
        return ethUtils.keccak256(
            Buffer.concat([
                ethUtils.toBuffer('matic-bor-receipt-'), // prefix for bor receipt
                ethUtils.setLengthLeft(ethUtils.toBuffer(block.number), 8), // 8 bytes of block number (BigEndian)
                ethUtils.toBuffer(block.hash), // block hash
            ])
        );
    }

    static getReceiptBytes(receipt: any) {
        let encodedData = rlp.encode([
            ethUtils.toBuffer(
                receipt.status !== undefined && receipt.status != null ? (receipt.status ? '0x1' : '0x') : receipt.root
            ),
            ethUtils.toBuffer(receipt.cumulativeGasUsed),
            ethUtils.toBuffer(receipt.logsBloom),
            // encoded log array
            receipt.logs?.map((l: any) => {
                // [address, [topics array], data]
                return [
                    ethUtils.toBuffer(l.address), // convert address to buffer
                    l.topics.map(ethUtils.toBuffer), // convert topics to buffer
                    ethUtils.toBuffer(l.data), // convert data to buffer
                ];
            }),
        ]);
        if (ProofUtil.isTypedReceipt(receipt)) {
            encodedData = Buffer.concat([ethUtils.toBuffer(receipt.type), encodedData]);
        }
        return encodedData;
    }

    static getRawHeader(_block: any) {
        if (typeof _block.difficulty !== 'string') {
            _block.difficulty = '0x' + _block.difficulty.toString(16);
        }
        const block = new Block(_block);
        return block.header;
    }
}
