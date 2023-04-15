import { ethers } from "hardhat";

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const Escrow = await ethers.getContractFactory("EscrowTest");
    const escrow = await Escrow.deploy();

    console.log("Escrow contract address:", escrow.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });