import { task, types } from "hardhat/config";
import type { HardhatRuntimeEnvironment } from "hardhat/types";
import json from "./deployment-info.json"
const fs = require("fs");
const path = require("path");


const main = async (args: any, hre: HardhatRuntimeEnvironment) => {
  const { ethers } = hre;
  const [signer] = await ethers.getSigners();
  const contractAddresses = JSON.parse(
    fs.readFileSync(path.join(__dirname, "../deployment-info.json")).toString().trim()
  );

  const baseSepoliaAddress = contractAddresses.baseSepolia;

  // const revertOptions = {
  //   abortAddress: args.abortAddress,
  //   callOnRevert: args.callOnRevert,
  //   onRevertGasLimit: args.onRevertGasLimit,
  //   revertAddress: args.revertAddress,
  //   revertMessage: ethers.utils.hexlify(
  //     ethers.utils.toUtf8Bytes(args.revertMessage)
  //   ),
  // };

  // const types = JSON.parse(args.types);

  // if (types.length !== args.values.length) {
  //   throw new Error(
  //     `The number of types (${types.length}) does not match the number of values (${args.values.length}).`
  //   );
  // }

  // const valuesArray = args.values.map((value: any, index: number) => {
  //   const type = types[index];

  //   if (type === "bool") {
  //     try {
  //       return JSON.parse(value.toLowerCase());
  //     } catch (e) {
  //       throw new Error(`Invalid boolean value: ${value}`);
  //     }
  //   } else if (type.startsWith("uint") || type.startsWith("int")) {
  //     return ethers.BigNumber.from(value);
  //   } else {
  //     return value;
  //   }
  // });
  // const encodedParameters = ethers.utils.defaultAbiCoder.encode(
  //   types,
  //   valuesArray
  // );

  const factory = (await hre.ethers.getContractFactory("BaseSepoliaContract")) as any;
  const contract = factory.attach(baseSepoliaAddress).connect(signer);
  const nftReceiver = args.nftReceiver ? args.nftReceiver : "0xF93EfaF39040BA4C32271E3256B8847fD94386DF";
  const tx = await contract.checkConditionAndSend(101, nftReceiver);

  await tx.wait();
  console.log(`Transaction hash: ${tx.hash}`);
};

task(
  "callBaseSepolia",
  "Make a call from a connected chain to a universal app on ZetaChain",
  main
)
