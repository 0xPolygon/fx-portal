type Account = {
  privateKey: string;
  balance: string;
};

type MockAccount = {
  secretKey: string;
  balance: string;
};

export const accounts: Account[] = [
  {
    privateKey:
      "0xc5e8f61d1ab959b397eecc0a37a6517b8e67a0e7cf1f4bce5591f3ed80199122",
    balance: "10000000000000000000000",
  },
  {
    privateKey:
      "0xd49743deccbccc5dc7baa8e69e5be03298da8688a15dd202e20f15d5e0e9a9fb",
    balance: "10000000000000000000000",
  },
  {
    privateKey:
      "0x23c601ae397441f3ef6f1075dcb0031ff17fb079837beadaf3c84d96c6f3e569",
    balance: "10000000000000000000000",
  },
  {
    privateKey:
      "0xee9d129c1997549ee09c0757af5939b2483d80ad649a0eda68e8b0357ad11131",
    balance: "10000000000000000000000",
  },
  {
    privateKey:
      "0x87630b2d1de0fbd5044eb6891b3d9d98c34c8d310c852f98550ba774480e47cc",
    balance: "10000000000000000000000",
  },
  {
    privateKey:
      "0x275cc4a2bfd4f612625204a20a2280ab53a6da2d14860c47a9f5affe58ad86d4",
    balance: "10000000000000000000000",
  },
  {
    privateKey:
      "0x7f307c41137d1ed409f0a7b028f6c7596f12734b1d289b58099b99d60a96efff",
    balance: "10000000000000000000000",
  },
  {
    privateKey:
      "0x2a8aede924268f84156a00761de73998dac7bf703408754b776ff3f873bcec60",
    balance: "10000000000000000000000",
  },
  {
    privateKey:
      "0x8b24fd94f1ce869d81a34b95351e7f97b2cd88a891d5c00abc33d0ec9501902e",
    balance: "10000000000000000000000",
  },
  {
    privateKey:
      "0x28d1bfbbafe9d1d4f5a11c3c16ab6bf9084de48d99fbac4058bdfa3c80b29085",
    balance: "10000000000000000000000",
  },
  {
    privateKey:
      "0x28d1bfbbafe9d1d4f5a11c3c16ab6bf9084de48d99fbac4058bdfa3c80b29086",
    balance: "10000000000000000000000",
  },
  {
    privateKey:
      "0x28d1bfbbafe9d1d4f5a11c3c16ab6bf9084de48d99fbac4058bdfa3c80b29087",
    balance: "10000000000000000000000",
  },
  {
    privateKey:
      "0x28d1bfbbafe9d1d4f5a11c3c16ab6bf9084de48d99fbac4058bdfa3c80b29088",
    balance: "10000000000000000000000",
  },
  {
    privateKey:
      "0x28d1bfbbafe9d1d4f5a11c3c16ab6bf9084de48d99fbac4058bdfa3c80b29089",
    balance: "10000000000000000000000",
  },
  {
    privateKey:
      "0x28d1bfbbafe9d1d4f5a11c3c16ab6bf9084de48d99fbac4058bdfa3c80b2908a",
    balance: "10000000000000000000000",
  },
  {
    privateKey:
      "0x28d1bfbbafe9d1d4f5a11c3c16ab6bf9084de48d99fbac4058bdfa3c80b2908b",
    balance: "10000000000000000000000",
  },
  {
    privateKey:
      "0x28d1bfbbafe9d1d4f5a11c3c16ab6bf9084de48d99fbac4058bdfa3c80b2908c",
    balance: "10000000000000000000000",
  },
  {
    privateKey:
      "0x28d1bfbbafe9d1d4f5a11c3c16ab6bf9084de48d99fbac4058bdfa3c80b2908d",
    balance: "10000000000000000000000",
  },
  {
    privateKey:
      "0x28d1bfbbafe9d1d4f5a11c3c16ab6bf9084de48d99fbac4058bdfa3c80b2908e",
    balance: "10000000000000000000000",
  },
  {
    privateKey:
      "0x28d1bfbbafe9d1d4f5a11c3c16ab6bf9084de48d99fbac4058bdfa3c80b2908f",
    balance: "10000000000000000000000",
  },
];

export const mockAccounts: MockAccount[] = accounts.map((a) => ({
  secretKey: a.privateKey,
  balance: a.balance,
}));
