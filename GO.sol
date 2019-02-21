pragma solidity ^0.4.23;

import "./Ownable.sol";
import "./TRC20.sol";

interface ITRC20 {
  
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

contract GO is TRC20, Ownable {
    using SafeMath for uint256;

    string public name;     //token name
    uint8 public decimals;  // 6
    string public symbol;   //
    
    address public foundationAddress;
    address public mintAddress;
    mapping(address => bool) private approvedAddresses;
    
    modifier onlyApprovedAddress() {
         require(approvedAddresses[msg.sender] == true);
         _;
    }

    constructor () public {
        _totalSupply = 10000000000000000; // 100 0000 0000 000000
        _balances[msg.sender] = _totalSupply;
        name = 'TRON GO';
        decimals = 6;
        symbol = 'GO';
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    function withdraw(uint amount) public onlyOwner {
        msg.sender.transfer(amount);
    }
    
    function addApprove(address _newContractAddress) public onlyOwner {
        approvedAddresses[_newContractAddress] = true;
    }
    
    function removeApprove(address _oldContractAddress) public onlyOwner {
        approvedAddresses[_oldContractAddress] = false;
    }
    
    function setMintAddress(address _mintAddress) public onlyOwner {
        mintAddress = _mintAddress;
    }
    
    function setFoundationAddress(address _foundationAddress) public onlyOwner {
        foundationAddress = _foundationAddress;
    }
    
    function mint(address _playerAddress, uint256 _mount) public onlyApprovedAddress returns (uint256) {
        uint8 mine = currentMiningDifficultyScale();
        uint256 mount = _mount.div(mine);
        
        require(_balances[mintAddress] > 0);
        _balances[mintAddress] = _balances[mintAddress].sub(mount);
        _balances[_playerAddress] = _balances[_playerAddress].add(mount);
        
        emit Mining(_playerAddress, now, mount);
        
        return mount;
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // LuckySolt access
    function operateGO(address _from, address _to, uint256 _amount) public onlyApprovedAddress returns (bool){
        _transfer(_from, _to, _amount);
        
        return true;
    }
    
    // Dividend access
    function frozen(address _playerAddress, uint256 _tokenAmount) public onlyApprovedAddress returns (bool) {
        _frozen(_playerAddress, _tokenAmount);
        
        return true;
    }
    
    // Dividend access
    function unfrozen(address _playerAddress) public onlyApprovedAddress returns (bool) {
        _unfrozen(_playerAddress);
        
        return true;
    }

    // Dividend access
    function extract(address _playerAddress) public onlyApprovedAddress returns (bool) {
        _extract(_playerAddress);
        
        return true;
    }
    
    function currentMiningDifficultyScale() public view returns (uint8) {
        uint8 miningScale = 1;
        if(_balances[mintAddress] <= 6000000000000000) {
            miningScale = 1;
        }else if(_balances[mintAddress] <= 5000000000000000) {
            miningScale = 2;
        }else if(_balances[mintAddress] <= 4000000000000000) {
            miningScale = 4;
        }else if(_balances[mintAddress] <= 3000000000000000) {
            miningScale = 8;
        }else if(_balances[mintAddress] <= 2000000000000000) {
            miningScale = 12;
        }else if(_balances[mintAddress] <= 1000000000000000) {
            miningScale = 16;
        }
        return miningScale;
    }
    
}
