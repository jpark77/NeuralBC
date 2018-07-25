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
    uint public min_ratio;
    uint public max_ratio;
    
    uint public eth_max_amt;
    uint public tok_max_amt;
    uint public eth_min_amt;
    uint public tok_min_amt;
    
    mapping (address => uint) public eth_amt;
    mapping (address => uint) public tok_amt;
    mapping (uint => address) public eth_users;
    mapping (uint => address) public tok_users;

    uint public total_eth;
    uint public total_tok;
    uint public ratio_eth;
    uint public ratio_tok;
    
    uint public cnt_eth;
    uint public cnt_tok;
    uint amt_get;

    uint unit;
    uint for_unit;
    uint ratio;
    uint for_ratio;

    bool public TimetoDeposit;

    uint i;
    uint j;
    
    uint256 public debug;

    function TokenExchange(address _token, uint _min_ratio, uint _max_ratio, uint _eth_max_amt){
        require(_max_ratio>=_min_ratio);
        token = _token;

        max_ratio = _max_ratio;
        min_ratio = _min_ratio;
        ratio = 4;
        for_ratio = 10**ratio;
        ratio_eth = 0;
        ratio_tok = 0;

        eth_max_amt = _eth_max_amt;
        tok_max_amt = eth_max_amt * max_ratio / for_ratio;
        eth_min_amt = 1*(10**18);
        tok_min_amt = (min_ratio+max_ratio)*eth_min_amt/(2*for_ratio);
        
        total_eth = 0;
        total_tok = 0;
        cnt_eth = 0;
        cnt_tok = 0;
        
        TimetoDeposit = true;
    }
    
    function depositEther() payable public {
        require(TimetoDeposit);
        require(msg.value >= eth_min_amt); //check min allowance
        require(total_eth+msg.value <= eth_max_amt); //check max allowance
        require(total_eth+msg.value > total_eth); //prevent overflow
        
        //update user, user's amount
        eth_amt[msg.sender] = safeAdd(eth_amt[msg.sender], msg.value);
        eth_users[cnt_eth++] = msg.sender;
        
        //update total amount, ratio
        total_eth += msg.value;
        
        ratio_eth = total_tok*for_ratio / total_eth;
        ratio_tok = (total_tok==0)? 0 : total_eth*for_ratio / total_tok;
    }

    function depositToken(uint amount) {
        require(TimetoDeposit);
        require(amount >= tok_min_amt); //check min allowance
        require(total_tok+amount <= tok_max_amt); //check max allowance
        require(total_tok+amount > total_tok); //prevent overflow
        
        //deposit
        if (!Token(token).transferFrom(msg.sender, address(this), amount)) throw;
        //update user, users's amount
        tok_amt[msg.sender] = safeAdd(tok_amt[msg.sender], msg.value);
        tok_users[cnt_tok++]=msg.sender;
        
        //update total amount, ratio
        total_tok += amount;  
        ratio_eth = (total_eth==0)? 0 : total_tok*for_ratio / total_eth;
        ratio_tok = total_eth*for_ratio / total_tok;        
    }


    function exchange(){
        TimetoDeposit = false;
        uint amt_send;
        uint amt_temp;

        //ether -> token
        i=0;
        while(i<cnt_eth){
            if(total_tok > 0){ //exchange
                if(total_tok-(eth_amt[eth_users[i]]*ratio_eth/for_ratio) < 0){ //send token partly
                    amt_temp = total_tok*for_ratio/ratio_eth;
                    eth_amt[eth_users[i]] -= (amt_temp+1);
                    if (!Token(token).transfer(tok_users[i], total_tok)) throw;
                } else { //send token
                    amt_send = eth_amt[tok_users[j]];
                    eth_amt[eth_users[i]] = safeSub(eth_amt[eth_users[i]], amt_send);
                    if (!Token(token).transfer(tok_users[i], amt_send*ratio_eth/for_ratio)) throw;
                    break;
                }
            } else {
                break;
            }
        }
        while(i<cnt_eth){ //send back ether
            if (!eth_users[i].call.value(eth_amt[eth_users[i]])()) throw;
            i++;
        }
        
        //token -> ether
        j=0;
        while(j<cnt_tok){
            if(total_eth > 0){ //exchange
                if(total_eth-(tok_amt[tok_users[j]]*ratio_tok/for_ratio) < 0){ //send ether partly
                    amt_temp = total_eth*for_ratio/ratio_tok;
                    tok_amt[tok_users[j]] -= (amt_temp+1);
                    if (!tok_users[j].call.value(tok_amt[tok_users[j]])() ) throw;
                } else { //send ether
                    amt_send = tok_amt[tok_users[j]];
                    tok_amt[tok_users[j]] = safeSub(tok_amt[tok_users[j]], amt_send);
                    if (!tok_users[j].call.value(amt_send*ratio_tok/for_unit)()) throw;
                    break;
                }
            } else {
                break;
            }
            j++;
        }
        while(j<cnt_tok){ //send back token
            amt_send = tok_amt[tok_users[j]];
            tok_amt[tok_users[j]] = safeSub(tok_amt[tok_users[j]], amt_send);
            if (!Token(token).transfer(tok_users[j], amt_send)) throw;
            j++;
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


