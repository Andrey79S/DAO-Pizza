const { ethers, upgrades } = require("hardhat");

async function main() {
  const Token = await ethers.getContractFactory("DAOPizzaToken");
  console.log("Deploying DAOPizzaToken (proxy)...");
  const token = await upgrades.deployProxy(Token, [1000000], { initializer: 'initialize' });
  await token.deployed();
  console.log("Token proxy deployed to:", token.address);

  const Sale = await ethers.getContractFactory("DAOPizzaSale");
  console.log("Deploying DAOPizzaSale...");
  const sale = await Sale.deploy();
  await sale.deployed();
  console.log("Sale deployed to:", sale.address);

  const transferAmount = ethers.utils.parseUnits("200000", 18);
  console.log("Transferring tokens to sale contract...");
  const tx = await token.transfer(sale.address, transferAmount);
  await tx.wait();
  console.log("Transferred tokens to sale");

  console.log('Deployment complete.');
  console.log("TOKEN:", token.address);
  console.log("SALE:", sale.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
