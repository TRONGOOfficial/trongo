pragma solidity ^0.4.23;

import "./SafeMath.sol";
import "./ITRC20.sol";

contract TRC20 is ITRC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances; // address balance and is miner account
    mapping (address => mapping (address => uint256)) private _allowed;

    mapping (address => uint256) internal _frozenToken; // address frozenbalance
    mapping (address => uint256) internal _extractToken;
    mapping (address => uint256) internal _extractTime; // address frozentime
    
    uint256 internal _totalSupply;
    uint256 internal _totalFrozen;
    
    uint256 constant UNFROZEN_TIME = 172800; // 60 * 60 * 24 * 2;
    
    event Mining(address indexed account, uint time, uint money);

    event Frozen(uint indexed time, address indexed account, uint money);
    event UnFrozen(uint indexed time, address indexed account, uint money, uint expireDate);
    event Extract(uint indexed time, address indexed account, uint money);

    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }
  
    function totalFrozen() public constant returns (uint256) {
        return _totalFrozen;
    }

    function balanceOf(address account) public constant returns (uint256) {
        return _balances[account];
    }
  
    function frozenOf(address account) public constant returns (uint256) {
        return _frozenToken[account];
    }
    
    function extractTokenOf(address account) public constant returns (uint256) {
        return _extractToken[account];
    }
    
    function extractTimeOf(address account) public constant returns (uint256) {
        return _extractTime[account];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom( address from, address to, uint256 value) public returns (bool) {
        require(value <= _balances[from]);
        require(value <= _allowed[from][msg.sender]);

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    function allowance(address account, address spender) public constant returns (uint256) {
        return _allowed[account][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(_balances[from] >= value);

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);

        emit Transfer(from, to, value);
    }

    function _frozen(address account, uint256 value) internal {
        require(_balances[account] >= value);
        
        _balances[account] = _balances[account].sub(value);
        _frozenToken[account] = _frozenToken[account].add(value);

        _totalFrozen = _totalFrozen.add(value);
        emit Frozen(now, account, value);
    }
    
    function _unfrozen(address account) internal {
        require(_frozenToken[account] > 0);
       
        uint256 value = _frozenToken[account];
        _frozenToken[account] = 0;
        _extractToken[account] = _extractToken[account].add(value);
        
        uint256 time = now.add(UNFROZEN_TIME);
        //uint256 time = now.add(600000);
        _extractTime[account] = time;
        
        _totalFrozen = _totalFrozen.sub(value);

        emit UnFrozen(now, account, value, time);
    }
  
    function _extract(address account) internal {
        require(_extractTime[account] <= now);
        require(_extractToken[account] > 0);

        uint256 value = _extractToken[account];
        
        _extractToken[account] = 0;
        _extractTime[account] = 0;
        _balances[account] = _balances[account].add(value);
        
        emit Extract(now, account, value);
    }

}