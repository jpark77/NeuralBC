pragma solidity ^0.4.9;

contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
  function assert(bool assertion) internal {
    if (!assertion) throw;
  }
}

contract TokenExchange is SafeMath {
    
    address public tokenA;
    address public tokenB;
    
    mapping (address => uint) public currentRatio;
    
    mapping (address => uint) public total_amt;

    mapping (address => mapping (uint => address)) public users;// User address : address user[token_address][index]
    mapping (address => mapping (address => uint)) public tokens; // User token amount : uint tokens[token_address][user_address]

    mapping (address => uint) cnt;
    uint amt_get;
    uint for_unit;

    bool TimetoDeposit;
    bool TimetoWithdraw;

    function TokenExchange(address _tokenA, address _tokenB){
        tokenA = _tokenA;
        tokenB = _tokenB;
        for_unit = 10000;
        TimetoDeposit = true;
        TimetoWithdraw = false;
    }
    
    function depositEther() payable {
        if(!TimetoDeposit) throw;
        if(msg.value<=0) throw;
        //if(tokens[0][msg.sender]==0) users[0][cnt[0]++] = msg.sender;
        tokens[0][msg.sender] = safeAdd(tokens[0][msg.sender], msg.value);
        //Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
    }

    function depositToken(address token, uint amount) {
        if(!TimetoDeposit) throw;
        if (token==0 || ( token!=tokenA && token!=tokenB )) throw;
        //if(tokens[token][msg.sender]==0) users[token][cnt[token]++] = msg.sender;
        if (!Token(token).transferFrom(msg.sender, address(this), amount)) throw;
        tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
        //Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
    }
    
    function withdrawEther(address token_get, address token_given){
        if (!TimetoWithdraw) throw;
        if (token_given !=0 ) throw;
        if (tokens[0][msg.sender] <= 0) throw;
        amt_get = tokens[token_given][msg.sender] * currentRatio[token_given] / for_unit;
        tokens[0][msg.sender] = 0;
        if (!msg.sender.call.value(amt_get)()) throw;
        //Withdraw(0, msg.sender, amount, tokens[0][msg.sender]);
    }
    
    function withdrawToken(address token_get, address token_given){
        if (!TimetoWithdraw) throw;
        if (token_get == 0) throw;
        if (tokens[token_given][msg.sender] <= 0) throw;
        amt_get = tokens[token_given][msg.sender] * currentRatio[token_given] / for_unit;
        tokens[token_given][msg.sender] = 0;
        if (!Token(token_get).transfer(msg.sender, amt_get)) throw;
    }
    
    function CalculateRatio(){
        if(TimetoWithdraw) throw;
        total_amt[tokenA] = (tokenA==0)? address(this).balance : Token(tokenA).balanceOf(address(this));
        total_amt[tokenB] = (tokenB==0)? address(this).balance : Token(tokenB).balanceOf(address(this));
        // if(total_amt[tokenA] == 0 || total_amt[tokenB]==0) SendBack();
        currentRatio[tokenA] = total_amt[tokenB]*for_unit/total_amt[tokenA];
        currentRatio[tokenB] = total_amt[tokenA]*for_unit/total_amt[tokenB];
    }

    function setTimetoExchange_true(){
        TimetoDeposit = false;
        TimetoWithdraw = true;
        //assert (total_amt[tokenA] == Token(tokenA).balanceOf(address(this)))
        //assert (total_amt[tokenB] == Token(tokenB).balanceOf(address(this)))
    }
    
    function GiveMeRest(){
        total_amt[tokenA] = (tokenA==0)? address(this).balance : Token(tokenA).balanceOf(address(this));
        total_amt[tokenB] = (tokenB==0)? address(this).balance : Token(tokenB).balanceOf(address(this));
        if(tokenA==0) msg.sender.call.value(amt_get)();
        else Token(tokenA).transfer(msg.sender, total_amt[tokenA]);
        if(tokenB==0) msg.sender.call.value(amt_get)();
        else Token(tokenB).transfer(msg.sender, total_amt[tokenB]);
    }
}

contract Token {
  function totalSupply() constant returns (uint256 supply) {}
  function balanceOf(address _owner) constant returns (uint256 balance) {}
  function transfer(address _to, uint256 _value) returns (bool success) {}
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
  function approve(address _spender, uint256 _value) returns (bool success) {}
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
}




