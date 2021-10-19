import { Contract, BigNumber } from 'ethers';
import { keccak256, solidityPack, toUtf8Bytes, defaultAbiCoder, getAddress } from 'ethers/lib/utils';
import { ethers } from 'hardhat';

export function addressFromNumber(n: number): string {
  const addressZeros = '0000000000000000000000000000000000000000';
  return `0x${addressZeros.substring(n.toString().length)}${n.toString()}`;
}

export async function latestBlockTimestamp(provider: typeof ethers.provider): Promise<number> {
  const latestBlockNumber = await provider.getBlockNumber();
  const block = await provider.getBlock(latestBlockNumber);
  return block.timestamp;
}

export async function mineBlocks(provider: typeof ethers.provider, count: number): Promise<void> {
  for (let i = 1; i < count; i++) {
    await provider.send('evm_mine', []);
  }
}

export async function mineBlockAtTime(provider: typeof ethers.provider, timestamp: number): Promise<void> {
  await provider.send('evm_mine', [timestamp]);
}

export async function increaseTime(provider: typeof ethers.provider, timestamp: number): Promise<void> {
  await provider.send('evm_increaseTime', [timestamp]);
}

export const MINIMUM_LIQUIDITY = BigNumber.from(10).pow(3);

const PERMIT_TYPEHASH = keccak256(
  toUtf8Bytes('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'),
);

export function expandTo18Decimals(n: number): BigNumber {
  return BigNumber.from(n).mul(BigNumber.from(10).pow(18));
}

function getDomainSeparator(name: string, tokenAddress: string, chainId: number) {
  return keccak256(
    defaultAbiCoder.encode(
      ['bytes32', 'bytes32', 'bytes32', 'uint256', 'address'],
      [
        keccak256(toUtf8Bytes('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')),
        keccak256(toUtf8Bytes(name)),
        keccak256(toUtf8Bytes('1')),
        chainId,
        tokenAddress,
      ],
    ),
  );
}

export function getCreate2Address(
  factoryAddress: string,
  [tokenA, tokenB]: [string, string],
  bytecode: string,
): string {
  const [token0, token1] = tokenA < tokenB ? [tokenA, tokenB] : [tokenB, tokenA];
  const create2Inputs = [
    '0xff',
    factoryAddress,
    keccak256(solidityPack(['address', 'address'], [token0, token1])),
    keccak256(bytecode),
  ];
  const sanitizedInputs = `0x${create2Inputs.map(i => i.slice(2)).join('')}`;
  return getAddress(`0x${keccak256(sanitizedInputs).slice(-40)}`);
}

export async function getApprovalDigest(
  token: Contract,
  approve: {
    owner: string;
    spender: string;
    value: BigNumber;
  },
  nonce: BigNumber,
  deadline: BigNumber,
  chainId: number,
): Promise<string> {
  const name = await token.name();
  const DOMAIN_SEPARATOR = getDomainSeparator(name, token.address, chainId);
  return keccak256(
    solidityPack(
      ['bytes1', 'bytes1', 'bytes32', 'bytes32'],
      [
        '0x19',
        '0x01',
        DOMAIN_SEPARATOR,
        keccak256(
          defaultAbiCoder.encode(
            ['bytes32', 'address', 'address', 'uint256', 'uint256', 'uint256'],
            [PERMIT_TYPEHASH, approve.owner, approve.spender, approve.value, nonce, deadline],
          ),
        ),
      ],
    ),
  );
}

export async function mineBlock(provider: typeof ethers.provider, timestamp: number): Promise<void> {
  // await new Promise(async (resolve, reject) => {
  //   (provider._web3Provider.sendAsync as any)(
  //     { jsonrpc: '2.0', method: 'evm_mine', params: [timestamp] },
  //     (error: any, result: any): void => {
  //       if (error) {
  //         reject(error);
  //       } else {
  //         resolve(result);
  //       }
  //     },
  //   );
  // });
  await provider.send('evm_setNextBlockTimestamp', [timestamp]);
}

export function encodePrice(reserveUSD: BigNumber, reserveQuote: BigNumber): BigNumber[] {
  return [
    reserveQuote.mul(BigNumber.from(2).pow(112)).div(reserveUSD),
    reserveUSD.mul(BigNumber.from(2).pow(112)).div(reserveQuote),
  ];
}
