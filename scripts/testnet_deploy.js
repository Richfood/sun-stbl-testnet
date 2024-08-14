const { ethers } = require("hardhat");

async function main() {
  // Deploy contracts
  const [deployer] = await ethers.getSigners();
  console.log("🚀 ~ main ~ deployer:", deployer.address)

  const SUNMinimealSTBL = await ethers.getContractFactory(
    "SUNMinimealSTBL"
  );
  const sUNMinimealSTBL = await SUNMinimealSTBL.deploy(
    deployer.address,
    deployer.address,
   1000000000
  );

  console.log("sunMinimealTBLCoin address:", sUNMinimealSTBL.address);
}

// Use an IIFE to be able to use async/await
(async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.error("Error deploying contracts:", error);
    process.exit(1);
  }
})();
