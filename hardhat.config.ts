import "@nomicfoundation/hardhat-toolbox";
import { HardhatUserConfig } from "hardhat/config";
import * as dotenv from "dotenv";

import "./tasks";
import "@zetachain/localnet/tasks";
import "@zetachain/toolkit/tasks";
import { getHardhatConfig } from "@zetachain/toolkit/client";

dotenv.config();
const baseConfig = getHardhatConfig({ accounts: [process.env.PRIVATE_KEY] });

const config: HardhatUserConfig = {
  ...baseConfig,
  networks: {
    ...baseConfig.networks,

  }
};

export default config;
