import { ethers } from "hardhat";

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const Escrow = await ethers.getContractFactory("ThreeTreeSocialEscrow");
    const escrow = await Escrow.deploy();

    console.log("Contract successfully deployed");
    console.log("ThreeTreeEscrow contract address:", escrow.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });