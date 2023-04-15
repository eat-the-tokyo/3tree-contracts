pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@opengsn/contracts/src/BaseRelayRecipient.sol";

contract Escrow is BaseRelayRecipient {
    uint256 private escrowCount = 0;

    struct EscrowData {
        address payable sender;
        address payable recipient;
        string email;
        bytes32 hashedEmail;
        uint256 amount;
        address tokenAddress;
        uint256 expiration;
        bool isActive;
        bool isClaimed;
        string wrapperType;
    }

    mapping(uint256 => EscrowData) public escrows;

        constructor(address _forwarder) {
            trustedForwarder = _forwarder;
        }

    function createEscrow(
        string memory email,
        bytes32 hashedEmail,
        address tokenAddress,
        uint256 amount,
        uint256 expiration,
        string memory wrapperType
    ) external payable {
        require(amount > 0, "Deposit amount must be greater than 0.");
        escrowCount++;

        if (tokenAddress == address(0)) {
            require(msg.value == amount, "Incorrect Ether amount sent.");
        } else {
            require(msg.value == 0, "Do not send Ether for token transfer.");
            IERC20(tokenAddress).transferFrom(
                _msgSender(),
                address(this),
                amount
            );
        }

        EscrowData memory newEscrow = EscrowData({
        sender: payable(_msgSender()),
        recipient: payable(address(0)),
        email: email,
        hashedEmail: hashedEmail,
        amount: amount,
        tokenAddress: tokenAddress,
        expiration: expiration,
        isActive: true,
        isClaimed: false,
        wrapperType: wrapperType
        });

        escrows[escrowCount] = newEscrow;
    }

    function withdraw(uint256 escrowId, bytes32 hashedEmail) external {
        EscrowData storage escrow = escrows[escrowId];
        require(escrow.isActive, "Escrow is not active.");
        require(escrow.hashedEmail == hashedEmail, "Invalid email hash.");
        require(block.timestamp <= escrow.expiration, "Escrow expired.");

        escrow.isActive = false;
        escrow.isClaimed = true;
        escrow.recipient = payable(_msgSender());

        if (escrow.tokenAddress == address(0)) {
            escrow.recipient.transfer(escrow.amount);
        } else {
            IERC20(escrow.tokenAddress).transfer(
                escrow.recipient,
                escrow.amount
            );
        }
    }

    function refund(uint256 escrowId) external {
        EscrowData storage escrow = escrows[escrowId];
        require(escrow.isActive, "Escrow is not active.");
        require(_msgSender() == escrow.sender, "Only the sender can refund.");
        require(block.timestamp > escrow.expiration, "Escrow has not expired.");

        escrow.isActive = false;
        escrow.recipient = escrow.sender;

        if (escrow.tokenAddress == address(0)) {
            escrow.sender.transfer(escrow.amount);
        } else {
            IERC20(escrow.tokenAddress).transfer(escrow.sender, escrow.amount);
        }
    }

    function getEscrowsByEmail(
        string memory email
    ) public view returns (uint256[] memory) {
        uint256[] memory matchingIds = new uint256[](escrowCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= escrowCount; i++) {
            if (
                keccak256(abi.encodePacked(escrows[i].email)) ==
                keccak256(abi.encodePacked(email)) &&
                escrows[i].isActive
            ) {
                matchingIds[index] = i;
                index++;
            }
        }
        uint256[] memory activeEscrows = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            activeEscrows[i] = matchingIds[i];
        }
        return activeEscrows;
    }

    function getEscrowHistoryByEmail(
        string memory email
    ) public view returns (uint256[] memory) {
        uint256[] memory matchingIds = new uint256[](escrowCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= escrowCount; i++) {
            if (
                keccak256(abi.encodePacked(escrows[i].email)) ==
                keccak256(abi.encodePacked(email))
            ) {
                matchingIds[index] = i;
                index++;
            }
        }
        uint256[] memory escrowHistory = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            escrowHistory[i] = matchingIds[i];
        }
        return escrowHistory;
    }

    function withdrawAllByEmail(
        string memory email,
        bytes32[] memory hashedEmails
    ) external {
        require(hashedEmails.length > 0, "No hashedEmails provided.");
        for (uint256 i = 0; i < hashedEmails.length; i++) {
            withdraw(escrowsByHashedEmail[hashedEmails[i]], hashedEmails[i]);
        }
    }

    function refundAllByEmail(
        string memory email,
        uint256[] memory escrowIds
    ) external {
        require(escrowIds.length > 0, "No escrowIds provided.");
        for (uint256 i = 0; i < escrowIds.length; i++) {
            refund(escrowIds[i]);
        }
    }

        function versionRecipient() external view override returns (string memory) {
            return "2.0.0";
        }
}