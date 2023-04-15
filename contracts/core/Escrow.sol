// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract ThreeTreeSocialEscrowBuilder is AccessControlEnumerable {

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    uint256 private chainId;

    //TODO: add Event Emission
    
    uint256 private escrowCount;

    enum TransactionSource {
        FROM_HOTWALLET,
        FROM_SNS
    }

    struct EscrowInfo {
        uint256 amount;
        address tokenAddress;
        uint256 expiration;
        bool isActive;
        bool isClaimed;
        string wrapperType;
        TransactionSource transactionType;
        uint256 prevEscrowId;
    }

    struct EscrowParticipants {
        address payable sender;
        string senderSnsId;
        address payable receiver;
        string receiverSnsId;
    }

    struct EscrowData {
        EscrowInfo info;
        EscrowParticipants participants;
        string signature;
    }

    mapping(bytes32 => EscrowData) public escrows;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(RELAYER_ROLE, _msgSender());

        chainId = block.chainid;
    }

    struct CreateEscrowFromHotWalletInput {
        string senderSnsId;
        address tokenAddress;
        uint256 amount;
        uint256 expiration;
        string wrapperType;
        string signature;
    }

    function getEscrowCount() public view returns (uint256) {
        return escrowCount;
    }


    function createEscrowFromHotWallet(CreateEscrowFromHotWalletInput memory input) external payable returns (bytes32) {
        require(input.amount > 0, "Deposit amount must be greater than 0.");

        if (input.tokenAddress == address(0)) {
            require(msg.value == input.amount, "Incorrect Ether amount sent.");
        } else {
            require(msg.value == 0, "Do not send Ether for token transfer.");
            IERC20(input.tokenAddress).transferFrom(_msgSender(), address(this), input.amount);
        }

        EscrowData memory newEscrow = EscrowData({
        info: EscrowInfo({
        amount: input.amount,
        tokenAddress: input.tokenAddress,
        expiration: input.expiration,
        isActive: true,
        isClaimed: false,
        wrapperType: input.wrapperType,
        transactionType: TransactionSource.FROM_HOTWALLET,
        prevEscrowId: 0
        }),
        participants: EscrowParticipants({
        sender: payable(_msgSender()),
        senderSnsId: input.senderSnsId,
        receiver: payable(address(0)),
        receiverSnsId: ""
        }),
        signature: input.signature
        });

        bytes32 escrowKey = generateEscrowKey();
        escrows[escrowKey] = newEscrow;

        return escrowKey;
    }

    function createEscrowFromSnsId(uint256 escrowId, uint256 amount) external returns (bytes32) {
        require(hasRole(RELAYER_ROLE, _msgSender()), "Caller is not a relayer");

        EscrowData storage originalEscrow = _getEscrowDataByEscrowCount(escrowId);
        require(originalEscrow.info.isActive, "Original escrow is not active");
        require(originalEscrow.info.amount >= amount, "Insufficient balance in original escrow");

        originalEscrow.info.amount -= amount;
        if (originalEscrow.info.amount < 1e14) { // If the remaining balance is too small
            originalEscrow.info.isActive = false;
        }

        EscrowData memory newEscrow = EscrowData({
        info: EscrowInfo({
        amount: amount,
        tokenAddress: originalEscrow.info.tokenAddress,
        expiration: originalEscrow.info.expiration,
        isActive: true,
        isClaimed: false,
        wrapperType: originalEscrow.info.wrapperType,
        transactionType: TransactionSource.FROM_SNS,
        prevEscrowId: escrowId
        }),
        participants: EscrowParticipants({
        sender: payable(_msgSender()),
        senderSnsId: originalEscrow.participants.senderSnsId,
        receiver: payable(address(0)),
        receiverSnsId: ""
        }),
        signature: originalEscrow.signature
        });

        bytes32 escrowKey = generateEscrowKey();
        escrows[escrowKey] = newEscrow;

        return escrowKey;
    }

    function _validateClaim(EscrowData storage escrow, string memory signature) internal view {
        require(escrow.info.isActive, "Escrow is not active");
        require(stringsEqual(escrow.signature, signature) , "Invalid signature");
        require(block.timestamp <= escrow.info.expiration, "Escrow expired");
    }

    function claim(uint256 escrowId, string memory signature, address receivingAddress) external {
        EscrowData storage escrow = _getEscrowDataByEscrowCount(escrowId);
        _validateClaim(escrow, signature);

        escrow.info.isActive = false;
        escrow.info.isClaimed = true;
        escrow.participants.receiver = payable(receivingAddress);

        if (escrow.info.tokenAddress == address(0)) {
            payable(_msgSender()).transfer(escrow.info.amount);
        } else {
            IERC20(escrow.info.tokenAddress).transfer(_msgSender(), escrow.info.amount);
        }
    }


    function refund(uint256 escrowId) external {
        EscrowData storage escrow = _getEscrowDataByEscrowCount(escrowId);
        require(escrow.info.isActive, "Escrow is not active");
        require(block.timestamp > escrow.info.expiration, "Escrow has not expired");

        if (escrow.info.transactionType == TransactionSource.FROM_SNS) {
            EscrowData storage prevEscrow = _getEscrowDataByEscrowCount(escrow.info.prevEscrowId);
            prevEscrow.info.amount += escrow.info.amount;
            if (prevEscrow.info.amount >= 1e14) {
                prevEscrow.info.isActive = true;
            }
        }

        escrow.info.isActive = false;

        if (escrow.info.tokenAddress == address(0)) {
            escrow.participants.sender.transfer(escrow.info.amount);
        } else {
            IERC20(escrow.info.tokenAddress).transfer(escrow.participants.sender, escrow.info.amount);
        }
    }

    function getEscrowDataByEscrowId(bytes32 escrowId) external view returns (EscrowData memory) {
        EscrowData storage escrowData = escrows[escrowId];

        return EscrowData(escrowData.info, escrowData.participants, "");
    }

    function _getEscrowDataByEscrowCount(uint256 count) private view returns (EscrowData storage) {
        bytes32 escrowKey = _retrieveEscrowKeyFromCount(count);
        EscrowData storage escrowData = escrows[escrowKey];

        return escrowData;
    }

    function getEscrowIdBySignature(string memory signature) internal view returns (uint256) {
        for (uint256 i = 0; i < escrowCount; i++) {
            if (stringsEqual(_getEscrowDataByEscrowCount(i).signature, signature)) {
                return i;
            }
        }
        revert("No matching escrow found");
    }

    function getEscrowIdsBySnsId(string memory snsId, bool onlyActive) public view returns (uint256[] memory) {
        uint256[] memory matchingIds = new uint256[](escrowCount);
        uint256 index = 0;
        for (uint256 i = 0; i < escrowCount; i++) {
            EscrowData memory escrow = _getEscrowDataByEscrowCount(i);
            if (stringsEqual(escrow.participants.receiverSnsId, snsId) && (!onlyActive || escrow.info.isActive)) {
                matchingIds[index] = i;
                index++;
            }
        }
        return trimArray(matchingIds, index);
    }

    function claimAllBySignatures(string[] memory signatures, address receivingAddress) external {
        require(signatures.length > 0, "No signatures provided.");
        for (uint256 i = 0; i < signatures.length; i++) {
            uint256 escrowId = getEscrowIdBySignature(signatures[i]);
            this.claim(escrowId, signatures[i], receivingAddress);
        }
    }

    function refundAllBySignatures(string[] memory signatures) external {
        require(signatures.length > 0, "No signatures provided.");
        for (uint256 i = 0; i < signatures.length; i++) {
            uint256 escrowId = getEscrowIdBySignature(signatures[i]);
            this.refund(escrowId);
        }
    }

    function isSignatureMatching(uint256 escrowId, string memory signature) external view returns(bool) {
        EscrowData memory escrow = _getEscrowDataByEscrowCount(escrowId);
        return keccak256(abi.encodePacked(escrow.signature)) == keccak256(abi.encodePacked(signature));
    }

    function generateEscrowKey() internal returns (bytes32) {
        escrowCount++;
        return keccak256(abi.encodePacked(chainId, escrowCount));
    }

    function _retrieveEscrowKeyFromCount(uint256 count) private view returns (bytes32) {
        return keccak256(abi.encodePacked(chainId, count));
    }


    function stringsEqual(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function trimArray(uint256[] memory array, uint256 newSize) private pure returns (uint256[] memory) {
        uint256[] memory trimmedArray = new uint256[](newSize);
        for (uint256 i = 0; i < newSize; i++) {
            trimmedArray[i] = array[i];
        }
        return trimmedArray;
    }
}