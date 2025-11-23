const { ethers } = require("hardhat");

async function main() {
  const ChainSaverTreasury = await ethers.getContractFactory("ChainSaverTreasury");
  const chainSaverTreasury = await ChainSaverTreasury.deploy();

  await chainSaverTreasury.deployed();

  console.log("ChainSaverTreasury contract deployed to:", chainSaverTreasury.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
