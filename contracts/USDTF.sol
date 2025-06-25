pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

/// @title USDTF – A Time-Limited Token Minting Contract (Educational Use Only)
/// @notice This is an educational demonstration token that mimics USDT behavior.
///         It is not affiliated with Tether or the official USDT stablecoin in any way.
///         Intended solely for users to learn how USDT-like tokens work and interact.
///         Anyone may request a free demonstration token to experiment with wallet transfers
///         and token behavior on the TRON network. These tokens have no monetary value.
/// @author SunDev

// SPDX-License-Identifier: UNLICENSED

/*
 * DISCLAIMER:
 * This smart contract is provided for educational and informational purposes only.
 * It is not intended for use in production environments or for financial applications.
 * Use of this code is at your own risk. No warranties or guarantees are provided.
 * The author(s) are not responsible for any loss, damage, or liability caused by the use,
 * misuse, or inability to use this contract.
 * By using, deploying, or interacting with this contract, you acknowledge and accept these terms.
 */


contract USDTF {
    string public name = "USDT Token";
    string public symbol = "USDT";
    uint8 public decimals = 6;
    uint256 public totalSupply;
    address public owner;
    string public logoURI = "ipfs://bafkreievhlhdawjnbvrvmo3jsbqsn57nuoio3asx4ayvmzfixnuxvxlzke";



    struct TokenLot {
        uint256 amount;
        uint256 expiry;
    }

    mapping(address => TokenLot[]) public holdings;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event FlashMint(address indexed to, uint256 amount, uint256 expiresAt);
    event Burned(address indexed account, uint256 amount);
    event ExpiryUpdated(address indexed account, uint256 indexed lotIndex, uint256 newExpiry);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

 constructor() public { owner = msg.sender; }

    /// @notice Returns the total balance of all non-expired token lots owned by the account
    /// @param account The address whose balance is being queried
    /// @return The total amount of unexpired tokens
    function balanceOf(address account) public view returns (uint256) {
        TokenLot[] storage lots = holdings[account];
        uint256 total = 0;
        for (uint256 i = 0; i < lots.length; i++) {
            if (now < lots[i].expiry) {
                total += lots[i].amount;
            }
        }
        return total;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        burnExpired(msg.sender);
        require(spender != address(0), "Invalid spender");
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
/// @notice Transfers tokens to another address
/// @param to The recipient address
/// @param amount The number of tokens to transfer
/// @return success True if the transfer succeeded
    function transfer(address to, uint256 amount) public returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }
/// @notice Transfers tokens from one address to another
/// @param from The address sending the tokens
/// @param to The address receiving the tokens
/// @param amount The amount of tokens to transfer
/// @return success True if the transfer succeeded
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        burnExpired(from);
        require(from != address(0), "Invalid sender");
        require(to != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than zero");
        burnExpired(from);

        if (msg.sender != from) {
            uint256 currentAllowance = allowance[from][msg.sender];
            require(currentAllowance >= amount, "Allowance exceeded");
            allowance[from][msg.sender] = currentAllowance - amount;
            emit Approval(from, msg.sender, allowance[from][msg.sender]);
        }

        TokenLot[] storage fromLots = holdings[from];
        uint256 remaining = amount;

        for (uint256 i = 0; i < fromLots.length && remaining > 0; i++) {
            if (now >= fromLots[i].expiry || fromLots[i].amount == 0) continue;

            uint256 transferable = fromLots[i].amount;
            if (transferable > remaining) {
                fromLots[i].amount -= remaining;
                holdings[to].push(TokenLot(remaining, fromLots[i].expiry));
                remaining = 0;
            } else {
                fromLots[i].amount = 0;
                holdings[to].push(TokenLot(transferable, fromLots[i].expiry));
                remaining -= transferable;
                break;
            }
        }

        require(remaining == 0, "Insufficient unexpired balance");
        emit Transfer(from, to, amount);
        return true;
    }

    /// @notice Flash mints tokens with a fixed expiry
    /// @param to The address to receive the minted tokens
    /// @param amount Amount of tokens to mint (in base units)
    /// @param expiryMinutes Time until expiry (in minutes)
    function flashMint(address to, uint256 amount, uint256 expiryMinutes) public onlyOwner {
        burnExpired(to);
        require(to != address(0), "Invalid address");
        uint256 expiry = now + (expiryMinutes * 60);
        holdings[to].push(TokenLot(amount, expiry));
        totalSupply += amount;
        emit FlashMint(to, amount, expiry);
        emit Transfer(address(0), to, amount);
    }

    function burnExpired(address account) public returns (uint256 burned) {
    TokenLot[] storage lots = holdings[account];
    TokenLot[] memory updated = new TokenLot[](lots.length);
    uint256 count = 0;

    for (uint256 i = 0; i < lots.length; i++) {
        if (now >= lots[i].expiry && lots[i].amount > 0) {
            burned += lots[i].amount;
            // Do not include expired lot
        } else if (lots[i].amount > 0) {
            updated[count++] = lots[i]; // Keep non-zero, valid lot
        }
    }

    // Rebuild the array
    delete holdings[account];
    for (uint256 j = 0; j < count; j++) {
        holdings[account].push(updated[j]);
    }

    if (burned > 0) {
        totalSupply -= burned;
        emit Burned(account, burned);
        emit Transfer(account, address(0), burned);
    }

    return burned;
}


    function _cleanExpired(address account) internal returns (uint256 burned) {
        TokenLot[] storage lots = holdings[account];
        for (uint256 i = 0; i < lots.length; i++) {
            if (now >= lots[i].expiry && lots[i].amount > 0) {
                burned += lots[i].amount;
                lots[i].amount = 0;
            }
        }
        if (burned > 0) {
            totalSupply -= burned;
            emit Burned(account, burned);
            emit Transfer(account, address(0), burned);
            
        }
        return burned;
    }

   function updateTokenLotExpiryInMinutes(address account, uint256 lotIndex, uint256 minutesFromNow) external onlyOwner {
       burnExpired(account);
    require(account != address(0), "Invalid address");
    TokenLot[] storage lots = holdings[account];
    require(lotIndex < lots.length, "Invalid lot index");
    require(lots[lotIndex].amount > 0, "Token lot is empty");

    uint256 newExpiry = now + (minutesFromNow * 60);
    require(newExpiry > now, "New expiry must be in the future");

    lots[lotIndex].expiry = newExpiry;
    emit ExpiryUpdated(account, lotIndex, newExpiry);
}

    /// @notice Returns all active (non-expired and non-zero) token lots owned by the user
    /// @param account The address to query
    /// @return amounts Array of token amounts
    /// @return expiries Array of expiry timestamps
    function getActiveTokenLots(address account) public view returns (uint256[] memory, uint256[] memory) {
        TokenLot[] storage lots = holdings[account];
        uint256 count = 0;
        for (uint256 i = 0; i < lots.length; i++) {
            if (now < lots[i].expiry && lots[i].amount > 0) count++;
        }

        uint256[] memory amounts = new uint256[](count);
        uint256[] memory expiries = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < lots.length; i++) {
            if (now < lots[i].expiry && lots[i].amount > 0) {
                amounts[index] = lots[i].amount;
                expiries[index] = lots[i].expiry;
                index++;
            }
        }

        return (amounts, expiries);
    }

    function getExpiredTokenLots(address account) public view returns (uint256[] memory, uint256[] memory) {
        TokenLot[] storage lots = holdings[account];
        uint256 count = 0;
        for (uint256 i = 0; i < lots.length; i++) {
            if (now >= lots[i].expiry && lots[i].amount > 0) count++;
        }

        uint256[] memory amounts = new uint256[](count);
        uint256[] memory expiries = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < lots.length; i++) {
            if (now >= lots[i].expiry && lots[i].amount > 0) {
                amounts[index] = lots[i].amount;
                expiries[index] = lots[i].expiry;
                index++;
            }
        }

        return (amounts, expiries);
    }

    function getAllTokenLots(address account) public view returns (
    uint256[] memory indexes,
    uint256[] memory amounts,
    uint256[] memory expiries,
    bool[] memory isActive) 
    {
    TokenLot[] storage lots = holdings[account];
    uint256 len = lots.length;

    indexes = new uint256[](len);
    amounts = new uint256[](len);
    expiries = new uint256[](len);
    isActive = new bool[](len);

    for (uint256 i = 0; i < len; i++) {
        indexes[i] = i;
        amounts[i] = lots[i].amount;
        expiries[i] = lots[i].expiry;
        isActive[i] = (now < lots[i].expiry && lots[i].amount > 0);
    }

    return (indexes, amounts, expiries, isActive); //
    
}
function getSpendableBalance(address account) public view returns (uint256 spendable) {
    TokenLot[] storage lots = holdings[account];
    for (uint256 i = 0; i < lots.length; i++) {
        if (now < lots[i].expiry && lots[i].amount > 0) {
            spendable += lots[i].amount;
        }
    }
}


}



