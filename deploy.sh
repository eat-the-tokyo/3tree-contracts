#!/bin/bash

#Deploy to Goerli Test Network
#echo "Deploying to Goerli Test Network..."
#npx hardhat run --network goerli ./scripts/deploy.ts

#Deploy to Polygon (Mumbai) Test Network
echo "Deploying to Polygon (Mumbai) Test Network..."
npx hardhat run --network polygon ./scripts/deploy.ts

#Deploy to Sepolia Test Network
echo "Deploying to Sepolia Test Network..."
npx hardhat run --network sepolia ./scripts/deploy.ts

#Deploy to Chiado Test Network
echo "Deploying to Chiado Test Network..."
npx hardhat run --network chiado ./scripts/deploy.ts

#Deploy to Alfajores Test Network
echo "Deploying to Alfajores Test Network..."
npx hardhat run --network alfajores ./scripts/deploy.ts

#Deploy to Hardhat Test Network
#echo "Deploying to Hardhat Test Network..."
#npx hardhat run --network hardhat ./scripts/deploy.ts