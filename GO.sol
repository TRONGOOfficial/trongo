pragma solidity ^0.4.23;

import "./Ownable.sol";
import "./TRC20.sol";

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