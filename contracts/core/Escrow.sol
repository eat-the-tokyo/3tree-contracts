pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract Escrow is AccessControlEnumerable {

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    uint256 private escrowCount = 0;

    enum TransactionSource {
        FROM_HOTWALLET,
        FROM_SNS
    }

    struct EscrowData {
        address payable sender;
        string senderSnsId;
        address payable receiver;
        string receiverSnsId;
        string hash;
        uint256 amount;
        address tokenAddress;
        uint256 expiration;
        bool isActive;
        bool isClaimed;
        string wrapperType;
        TransactionSource transactionType;
        uint256 prevEscrowId;
    }

    mapping(uint256 => EscrowData) public escrows;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(RELAYER_ROLE, _msgSender());
    }

    function createEscrowFromHotWallet(
        string memory senderSnsId,
        string memory hash,
        address tokenAddress,
        uint256 amount,
        uint256 expiration,
        string memory wrapperType
    ) external payable {
        require(amount > 0, "Deposit amount must be greater than 0.");

        if (tokenAddress == address(0)) {
            require(msg.value == amount, "Incorrect Ether amount sent.");
        } else {
            require(msg.value == 0, "Do not send Ether for token transfer.");
            IERC20(tokenAddress).transferFrom(_msgSender(), address(this), amount);
        }

        EscrowData memory newEscrow = EscrowData({
        sender: payable(_msgSender()),
        senderSnsId: senderSnsId,
        receiver: payable(address(0)),
        receiverSnsId: "",
        hash: hash,
        amount: amount,
        tokenAddress: tokenAddress,
        expiration: expiration,
        isActive: true,
        isClaimed: false,
        wrapperType: wrapperType,
        transactionType: TransactionSource.FROM_HOTWALLET,
        prevEscrowId: 0
        });

        escrows[escrowCount] = newEscrow;

        escrowCount++;
    }

    // sendviaemail
    function createEscrowFromSns(uint256 escrowId, uint256 amount) external {
        require(hasRole(RELAYER_ROLE, _msgSender()), "Caller is not a relayer");

        EscrowData storage originalEscrow = escrows[escrowId];
        require(originalEscrow.isActive, "Original escrow is not active");
        require(originalEscrow.amount >= amount, "Insufficient balance in original escrow");

        originalEscrow.amount -= amount;
        if (originalEscrow.amount < 1e14) { // If the remaining balance is too small
            originalEscrow.isActive = false;
        }

        EscrowData memory newEscrow = EscrowData({
        sender: payable(_msgSender()),
        senderSnsId: originalEscrow.senderSnsId,
        receiver: payable(address(0)),
        receiverSnsId: "",
        hash: originalEscrow.hash,
        amount: amount,
        tokenAddress: originalEscrow.tokenAddress,
        expiration: originalEscrow.expiration,
        isActive: true,
        isClaimed: false,
        wrapperType: originalEscrow.wrapperType,
        transactionType: TransactionSource.FROM_SNS,
        prevEscrowId: escrowId
        });

        escrows[escrowCount] = newEscrow;

        escrowCount++;
    }

    function claim(uint256 escrowId, string memory hash, address receivingAddress) external {
        EscrowData storage escrow = escrows[escrowId];
        require(escrow.isActive, "Escrow is not active");
        require(stringsEqual(escrow.hash, hash), "Invalid hash");
        require(block.timestamp <= escrow.expiration, "Escrow expired");

        escrow.isActive = false;
        escrow.isClaimed = true;
        escrow.receiver = payable(receivingAddress);

        if (escrow.tokenAddress == address(0)) {
            payable(_msgSender()).transfer(escrow.amount);
        } else {
            IERC20(escrow.tokenAddress).transfer(_msgSender(), escrow.amount);
        }
    }


    function refund(uint256 escrowId) external {
        EscrowData storage escrow = escrows[escrowId];
        require(escrow.isActive, "Escrow is not active");
        require(block.timestamp > escrow.expiration, "Escrow has not expired");

        if (escrow.transactionType == TransactionSource.FROM_SNS) {
            EscrowData storage prevEscrow = escrows[escrow.prevEscrowId];
            prevEscrow.amount += escrow.amount;
            if (prevEscrow.amount >= 1e14) {
                prevEscrow.isActive = true;
            }
        }

        escrow.isActive = false;

        if (escrow.tokenAddress == address(0)) {
            escrow.sender.transfer(escrow.amount);
        } else {
            IERC20(escrow.tokenAddress).transfer(escrow.sender, escrow.amount);
        }
    }

    function getEscrowDataByEscrowId(uint256 id) internal view returns (EscrowData memory) {
        require(id >= 0 && id < escrowCount, "Escrow ID does not exist");
        return escrows[id];
    }

    function getEscrowIdByHash(string memory hash) internal view returns (uint256) {
        for (uint256 i = 1; i <= escrowCount; i++) {
            if (stringsEqual(escrows[i].hash, hash)) {
                return i;
            }
        }
        revert("No matching escrow found");
    }

    function getActiveEscrowIdBySnsId(string memory snsId) public view returns (uint256[] memory) {
        uint256[] memory matchingIds = new uint256[](escrowCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= escrowCount; i++) {
            if (stringsEqual(escrows[i].receiverSnsId, snsId) && escrows[i].isActive) {
                matchingIds[index] = i;
                index++;
            }
        }
        uint256[] memory _escrows = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            _escrows[i] = matchingIds[i];
        }
        return _escrows;
    }

    function getAllEscrowIdsBySnsId(string memory snsId) public view returns (uint256[] memory) {
        uint256[] memory matchingIds = new uint256[](escrowCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= escrowCount; i++) {
            if (stringsEqual(escrows[i].receiverSnsId, snsId) && escrows[i].isActive) {
                matchingIds[index] = i;
                index++;
            }
        }
        uint256[] memory _escrows = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            _escrows[i] = matchingIds[i];
        }
        return _escrows;
    }

    function claimAllByHashes(string[] memory hashes, address receivingAddress) external {
        require(hashes.length > 0, "No hashes provided.");
        for (uint256 i = 0; i < hashes.length; i++) {
            uint256 escrowId = getEscrowIdByHash(hashes[i]);
            this.claim(escrowId, hashes[i], receivingAddress);
        }
    }

    function refundAllByHashes(string[] memory hashes) external {
        require(hashes.length > 0, "No hashes provided.");
        for (uint256 i = 0; i < hashes.length; i++) {
            uint256 escrowId = getEscrowIdByHash(hashes[i]);
            this.refund(escrowId);
        }
    }

    function stringsEqual(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}