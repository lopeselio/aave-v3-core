// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import {Context} from '../../dependencies/openzeppelin/contracts/Context.sol';
import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {IERC20Detailed} from '../../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {IAaveIncentivesController} from '../../interfaces/IAaveIncentivesController.sol';

/**
 * @title IncentivizedERC20
 * @author Aave, inspired by the Openzeppelin ERC20 implementation
 * @notice Basic ERC20 implementation
 **/
abstract contract IncentivizedERC20 is Context, IERC20, IERC20Detailed {
  mapping(address => uint256) internal _balances;

  mapping(address => mapping(address => uint256)) private _allowances;
  uint256 internal _totalSupply;
  string private _name;
  string private _symbol;
  uint8 private _decimals;
  IAaveIncentivesController internal _incentivesController;

  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /// @inheritdoc IERC20Detailed
  function name() public view override returns (string memory) {
    return _name;
  }

  /// @inheritdoc IERC20Detailed
  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  /// @inheritdoc IERC20Detailed
  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  /// @inheritdoc IERC20
  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  /// @inheritdoc IERC20
  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  /**
   * @notice Returns the address of the incentives controller contract
   * @return Incentivescontroller
   **/
  function getIncentivesController() external view virtual returns (IAaveIncentivesController) {
    return _incentivesController;
  }

  /// @inheritdoc IERC20
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /// @inheritdoc IERC20
  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  /// @inheritdoc IERC20
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /// @inheritdoc IERC20
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
    return true;
  }

  /**
   * @notice Increases the allowance of spender to spend _msgSender() tokens
   * @param spender The user allowed to spend on behalf of _msgSender()
   * @param addedValue The amount being added to the allowance
   * @return `true`
   **/
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }

  /**
   * @notice Decreases the allowance of spender to spend _msgSender() tokens
   * @param spender The user allowed to spend on behalf of _msgSender()
   * @param subtractedValue The amount being subtracted to the allowance
   * @return `true`
   **/
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    uint256 oldSenderBalance = _balances[sender];
    _balances[sender] = oldSenderBalance - amount;
    uint256 oldRecipientBalance = _balances[recipient];
    _balances[recipient] = _balances[recipient] + amount;

    IAaveIncentivesController incentivesControllerLocal = _incentivesController;
    if (address(incentivesControllerLocal) != address(0)) {
      uint256 currentTotalSupply = _totalSupply;
      incentivesControllerLocal.handleAction(sender, currentTotalSupply, oldSenderBalance);
      if (sender != recipient) {
        incentivesControllerLocal.handleAction(recipient, currentTotalSupply, oldRecipientBalance);
      }
    }
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    uint256 oldTotalSupply = _totalSupply;
    _totalSupply = oldTotalSupply + amount;

    uint256 oldAccountBalance = _balances[account];
    _balances[account] = oldAccountBalance + amount;

    IAaveIncentivesController incentivesControllerLocal = _incentivesController;
    if (address(incentivesControllerLocal) != address(0)) {
      incentivesControllerLocal.handleAction(account, oldTotalSupply, oldAccountBalance);
    }
  }

  function _burn(address account, uint256 amount) internal virtual {
    uint256 oldTotalSupply = _totalSupply;
    _totalSupply = oldTotalSupply - amount;

    uint256 oldAccountBalance = _balances[account];
    _balances[account] = oldAccountBalance - amount;

    IAaveIncentivesController incentivesControllerLocal = _incentivesController;

    if (address(incentivesControllerLocal) != address(0)) {
      incentivesControllerLocal.handleAction(account, oldTotalSupply, oldAccountBalance);
    }
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _setName(string memory newName) internal {
    _name = newName;
  }

  function _setSymbol(string memory newSymbol) internal {
    _symbol = newSymbol;
  }

  function _setDecimals(uint8 newDecimals) internal {
    _decimals = newDecimals;
  }
}