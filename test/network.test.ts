// async function callContractFunction() {
//   try {
//     const gasEstimate = await contract.methods.myFunction(param1, param2).estimateGas();
//     const gasPrice = await web3.eth.getGasPrice();
//     const totalFee = gasEstimate * gasPrice;
//
//     const result = await contract.methods.myFunction(param1, param2).send({
//       from: account.address,
//       gas: gasEstimate,
//       gasPrice: gasPrice
//     });
//
//     console.log('Transaction hash:', result.transactionHash);
//     console.log('Total fee:', totalFee);
//   } catch (error) {
//     console.error('Error:', error);
//   }
// }
//
// const Web3 = require('web3');
// const contractABI = require('./path/to/contractABI.json');
//
// const web3 = new Web3('https://mainnet.infura.io/v3/<YOUR_INFURA_PROJECT_ID>');
// const privateKey = '<YOUR_PRIVATE_KEY>';
//
// const account = web3.eth.accounts.privateKeyToAccount(privateKey);
//
// const contractAddress = '<CONTRACT_ADDRESS>';
// const contract = new web3.eth.Contract(contractABI, contractAddress);
