#!/bin/bash

# Deploy to Sepolia Test Network
echo "Deploying to sepolia Test Network..."
npx hardhat run --network sepolia ./scripts/deploy.ts

# Deploy to Polygon (Mumbai) Test Network
#echo "Deploying to Polygon (Mumbai) Test Network..."
#npx hardhat run --network polygon ./scripts/deploy.ts