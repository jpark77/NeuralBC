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
    address public creator;
    address public tokenA;
    address public tokenB;
    
    uint public min_ratio;
    uint public max_ratio;
    uint amt_get;
    uint unit;
    uint for_unit;
    uint rest_amt;

    bool TimetoDeposit;
    bool TimetoWithdraw;
    bool FirstDeposit;

    mapping (address => uint) public currentRatio;
    mapping (address => uint) public total_amt;
    mapping (address => mapping (address => uint)) public tokens; // User token amount : uint tokens[token_address][user_address]

    function TokenExchange(address _tokenA, address _tokenB, uint _min_ratio, uint _max_ratio, uint amount){
        if(_tokenA == _tokenB) throw;
        
        tokenA = _tokenA;
        tokenB = _tokenB;
        max_ratio = _max_ratio;
        min_ratio = _min_ratio;
        total_amt[tokenA] = 0;
        total_amt[tokenB] = 0;
        currentRatio[tokenA] = 0;
        currentRatio[tokenB] = 0;
        
        unit = 10;
        for_unit = 10**unit;
        
        TimetoDeposit = true;
        TimetoWithdraw = false;
        
        creator = msg.sender;
        FirstDeposit = true;
    }
    
    function depositEther() payable {
        if(!TimetoDeposit) throw;
        if(msg.value<=0) throw; // require(msg.value>0);
        if(tokenA==0){
            if(total_amt[tokenB] > total_amt[0]+msg.value || total_amt[0]+msg.value > total_amt[tokenB]*max_ratio) throw;
            tokens[0][msg.sender] = safeAdd(tokens[0][msg.sender], msg.value);
            total_amt[0] = address(this).balance;
            currentRatio[0] = total_amt[tokenB]*for_unit / total_amt[0];
            currentRatio[tokenB] = total_amt[0]*for_unit / total_amt[tokenB];
        } else if(tokenB==0){
            if( (total_amt[0]+msg.value) > total_amt[tokenA] || total_amt[tokenA] > (total_amt[0]+msg.value)*max_ratio ) throw;
            tokens[0][msg.sender] = safeAdd(tokens[0][msg.sender], msg.value);
            total_amt[0] = address(this).balance;
            currentRatio[tokenA] = total_amt[tokenA]*for_unit / total_amt[0];
            currentRatio[0] = total_amt[0]*for_unit / total_amt[tokenA];
        } else { throw; }
    }

    function depositToken(address token, uint amount) {
        if(!TimetoDeposit) throw;
        if (token==0 || ( token!=tokenA && token!=tokenB )) throw;
        if(token==tokenA){
            if(total_amt[tokenB] > total_amt[tokenA]+amount || total_amt[tokenA]+amount > total_amt[tokenB]*max_ratio) throw;
            if (!Token(token).transferFrom(msg.sender, address(this), amount)) throw;
            tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
            total_amt[token] += amount;
            currentRatio[token] = total_amt[tokenB]*for_unit / total_amt[token];
            currentRatio[tokenB] = total_amt[token]*for_unit / total_amt[tokenB];
        } else if(token==tokenB){
            if( (total_amt[tokenB]+amount) > total_amt[tokenA] || total_amt[tokenA] > (total_amt[tokenB]+amount)*max_ratio ) throw;
            if (!Token(token).transferFrom(msg.sender, address(this), amount)) throw;
            tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
            total_amt[token] += amount;
            currentRatio[tokenA] = total_amt[tokenA]*for_unit / total_amt[token];
            currentRatio[token] = total_amt[token]*for_unit / total_amt[tokenA];
        } else { throw; }
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
    
    function withdrawforCreator(){
        if(msg.sender!=creator) throw;
        if(total_amt[tokenA]*min_ratio > total_amt[tokenB]) {
            rest_amt= (total_amt[tokenA]*min_ratio - total_amt[tokenB])/min_ratio;
            //transfer(rest);
            if (!msg.sender.call.value(rest_amt)()) throw;
        }
    }
    
    function CalculateRatio(){
        if(TimetoWithdraw) throw;
        //total_amt[tokenA] = (tokenA==0)? address(this).balance : Token(tokenA).balanceOf(address(this));
        //total_amt[tokenB] = (tokenB==0)? address(this).balance : Token(tokenB).balanceOf(address(this));
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
    
    function FirstDepositEtherForCreator(){
        require(msg.sender==creator);

        if(!TimetoDeposit) throw;
        if(msg.value<=0) throw; // require(msg.value>0);
        if(tokenA==0){
            if(total_amt[tokenB] > total_amt[0]+msg.value || total_amt[0]+msg.value > total_amt[tokenB]*max_ratio) throw;
            tokens[0][msg.sender] = safeAdd(tokens[0][msg.sender], msg.value);
            total_amt[0] = address(this).balance;
            currentRatio[0] = total_amt[tokenB]*for_unit / total_amt[0];
            currentRatio[tokenB] = total_amt[0]*for_unit / total_amt[tokenB];
        } else if(tokenB==0){
            if( (total_amt[0]+msg.value) > total_amt[tokenA] || total_amt[tokenA] > (total_amt[0]+msg.value)*max_ratio ) throw;
            tokens[0][msg.sender] = safeAdd(tokens[0][msg.sender], msg.value);
            total_amt[0] = address(this).balance;
            currentRatio[tokenA] = total_amt[tokenA]*for_unit / total_amt[0];
            currentRatio[0] = total_amt[0]*for_unit / total_amt[tokenA];
        } else { throw; }

        FirstDeposit = false;
    }

    function FirstDepositTokenForCreator(){
        require(msg.sender==creator);
        
        if(!TimetoDeposit) throw;
        if(msg.value<=0) throw; // require(msg.value>0);
        if(tokenA==0){
            if(total_amt[tokenB] > total_amt[0]+msg.value || total_amt[0]+msg.value > total_amt[tokenB]*max_ratio) throw;
            tokens[0][msg.sender] = safeAdd(tokens[0][msg.sender], msg.value);
            total_amt[0] = address(this).balance;
            currentRatio[0] = total_amt[tokenB]*for_unit / total_amt[0];
            currentRatio[tokenB] = total_amt[0]*for_unit / total_amt[tokenB];
        } else if(tokenB==0){
            if( (total_amt[0]+msg.value) > total_amt[tokenA] || total_amt[tokenA] > (total_amt[0]+msg.value)*max_ratio ) throw;
            tokens[0][msg.sender] = safeAdd(tokens[0][msg.sender], msg.value);
            total_amt[0] = address(this).balance;
            currentRatio[tokenA] = total_amt[tokenA]*for_unit / total_amt[0];
            currentRatio[0] = total_amt[0]*for_unit / total_amt[tokenA];
        } else { throw; }        
        
        FirstDeposit = false;
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


