async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  // 1) Deploy token with initial supply (e.g., 1_000_000 tokens with 18 decimals)
  const initialSupply = ethers.utils.parseUnits("1000000", 18); // 1,000,000
  const Token = await ethers.getContractFactory("DAOPIZZA");
  const token = await Token.deploy(initialSupply);
  await token.deployed();
  console.log("DAOPIZZA deployed to:", token.address);

  // 2) Deploy TokenSale with price: e.g., 0.001 ETH per token unit (i.e. 0.001 ETH for 1 token)
  // priceWeiPerToken = 0.001 * 1e18 = 1e15
  const priceWeiPerToken = ethers.utils.parseEther("0.001");
  const Sale = await ethers.getContractFactory("TokenSale");
  const sale = await Sale.deploy(token.address, priceWeiPerToken);
  await sale.deployed();
  console.log("TokenSale deployed to:", sale.address);

  // 3) Transfer some tokens to sale contract (for sale). E.g., transfer 200k tokens
  const tokensForSale = ethers.utils.parseUnits("200000", 18);
  const tx = await token.transfer(sale.address, tokensForSale);
  await tx.wait();
  console.log("Transferred", tokensForSale.toString(), "tokens to sale contract");

  console.log("Ready. Use Hardhat node and deploy: npx hardhat node  (in separate terminal), then run:");
  console.log("npx hardhat run --network localhost scripts/deploy.js");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
