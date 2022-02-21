import storage from "../storage/CRandom";
import { TezosToolkit } from "@taquito/taquito";
import config from "../config";
import { migrate } from "../scripts/commands/migrate/utils";
import { NetworkLiteral, TezosAddress } from "../utils/helpers";

module.exports = async (tezos: TezosToolkit, network: NetworkLiteral) => {
  const contractAddress: TezosAddress = await migrate(
    tezos,
    config.outputDirectory,
    "CRandom",
    storage,
    network
  );
  console.log(`CRandom contract address: ${contractAddress}`);
};
