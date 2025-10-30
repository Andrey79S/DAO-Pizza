const { ethers, upgrades } = require("hardhat");

async function main() {
  const proxyAddress = "<PASTE_PROXY_ADDRESS>";
  const NewToken = await ethers.getContractFactory("DAOPizzaToken");
  console.log("Upgrading implementation...");
  await upgrades.upgradeProxy(proxyAddress, NewToken);
  console.log("Upgrade done");
}

main().catch((e) => { console.error(e); process.exitCode = 1; });
