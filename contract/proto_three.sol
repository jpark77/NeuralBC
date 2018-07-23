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
    
    address public token;
    uint min_ratio;
    uint max_ratio;
    
    uint eth_max_amt;
    uint tok_max_amt;
    
    mapping (address => uint) public eth_amt;
    mapping (address => uint) public tok_amt;
    mapping (uint => address) public eth_users;
    mapping (uint => address) public tok_users;

    uint total_eth;
    uint total_tok;
    uint ratio_eth;
    uint ratio_tok;
    
    uint cnt_eth;
    uint cnt_tok;
    uint amt_get;
    uint deposit_min_ether;
    uint deposit_min_token;
    uint unit;
    uint for_unit;

    uint amt_send;

    bool TimetoDeposit;
    bool TimetoWithdraw;

    function TokenExchange(address _token, uint _min_ratio, uint _max_ratio, uint _eth_max_amt, uint _tok_max_amt){
        require(_token != 0);
        
        token = _token;
        max_ratio = _max_ratio;
        min_ratio = _min_ratio;
        eth_max_amt = _eth_max_amt;
        tok_max_amt = _tok_max_amt;
        ratio_eth = 0;
        ratio_tok = 0;
        
        total_eth = 0;
        total_tok = 0;
        cnt_eth = 0;
        cnt_tok = 0;
        
        deposit_min_ether = 1;
        deposit_min_token = (min_ratio+max_ratio)/2 * deposit_min_ether;
        unit = 10;
        for_unit = 10**unit;
        
        
        TimetoDeposit = true;
        TimetoWithdraw = false;
    }
    
    function depositEther() payable {
        require(TimetoDeposit);
        require(msg.value > deposit_min_ether);
        require(total_eth+msg.value < eth_max_amt);
        
        eth_amt[msg.sender] = safeAdd(eth_amt[msg.sender], msg.value);
        eth_users[cnt_eth++] = msg.sender;
        
        require(total_eth+msg.value > total_eth);
        total_eth += msg.value;  //update amount, ratio
        ratio_eth = total_tok*for_unit / total_eth;
        ratio_tok = (total_tok==0)? 0 : total_eth*for_unit / total_tok;
    }

    function depositToken(uint amount) payable {
        require(TimetoDeposit);
        require(amount > deposit_min_token);
        require(total_tok+amount > total_tok);
        
        if (!Token(token).transferFrom(msg.sender, address(this), amount)) throw;
        tok_users[cnt_tok++]=msg.sender;
        
        tok_amt[msg.sender] = safeAdd(tok_amt[msg.sender], msg.value);
        total_tok += amount;  //update amount, ratio
        ratio_eth = (total_eth==0)? 0 : total_tok*for_unit / total_eth;
        ratio_tok = total_eth*for_unit / total_tok;        
    }

    function exchange(){
        TimetoDeposit = false;
        TimetoWithdraw = true;
        
        
        //send eth
        for(uint i=0; i<cnt_eth; i++){
            amt_send = eth_amt[eth_users[i]] * ratio_eth / for_unit;
            if (!eth_users[i].call.value(amt_send)()) throw;
            eth_amt[eth_users[i]] = 0;
        }
        //send tok
        for(uint j=0; j<cnt_tok; j++){
            amt_send = tok_amt[tok_users[j]] * ratio_tok / for_unit;
            if(!Token(token).transfer(tok_users[j], amt_send)) throw;
        }
        
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


