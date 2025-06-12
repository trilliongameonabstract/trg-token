// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./utils/ERC20.sol";
import "./utils/ERC20Permit.sol";
import "./utils/Ownable.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/SafeMath.sol";

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract TrillionGame is ERC20, ERC20Permit, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18; // 1B TRG
    uint256 public devFee = 1; // 1%
    uint256 public maxTxAmount = MAX_SUPPLY.mul(1).div(100); // Anti-whale 1%

    bool public tradingEnabled = false;

    address public devWallet;
    address public immutable routerAddress;
    mapping(address => bool) private _isExcludedFromFees;

    event DevFeeTaken(address from, uint256 amount);
    event TradingEnabled();

    constructor(address _router, address _devWallet)
        ERC20("Trillion Game", "TRG")
        ERC20Permit("Trillion Game")
        Ownable(msg.sender)
    {
        require(_router != address(0) && _devWallet != address(0), "Zero address");
        _mint(msg.sender, MAX_SUPPLY);
        routerAddress = _router;
        devWallet = _devWallet;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[devWallet] = true;
    }

    function setDevWallet(address wallet) external onlyOwner {
        require(wallet != address(0), "Zero address");
        devWallet = wallet;
    }

    function setDevFee(uint256 fee) external onlyOwner {
        require(fee <= 5, "Max 5%");
        devFee = fee;
    }

    function setMaxTxAmount(uint256 amount) external onlyOwner {
        require(amount >= MAX_SUPPLY / 1000, "Too small");
        maxTxAmount = amount;
    }

    function excludeFromFees(address account, bool excluded) external onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function enableTrading() external onlyOwner {
        tradingEnabled = true;
        emit TradingEnabled();
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal override virtual {
        require(tradingEnabled || _isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not enabled");

        if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            require(amount <= maxTxAmount, "Exceeds max tx limit");
            uint256 feeAmount = amount.mul(devFee).div(100);
            super._transfer(from, devWallet, feeAmount);
            emit DevFeeTaken(from, feeAmount);
            amount = amount.sub(feeAmount);
        }

        super._transfer(from, to, amount);
    }

    receive() external payable {}

    function addInitialLiquidity(uint256 tokenAmount) external payable onlyOwner nonReentrant {
        _approve(address(this), routerAddress, tokenAmount);
        IUniswapV2Router02(routerAddress).addLiquidityETH{value: msg.value}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }
}