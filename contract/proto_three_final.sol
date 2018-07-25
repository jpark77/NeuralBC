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
    uint public rest_eth;
    uint public rest_tok;
    uint public ratio_eth;
    uint public ratio_tok;
    
    uint public cnt_eth;
    uint public cnt_tok;
    uint amt_get;
    uint amt_send;
    uint amt_temp;

    uint ratio;
    uint for_ratio;

    bool public TimetoDeposit;

    uint i;
    uint j;
    
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
        tok_min_amt = eth_min_amt*min_ratio/for_ratio;
        //tok_min_amt = (min_ratio+max_ratio)*eth_min_amt/(2*for_ratio);
        
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
        tok_amt[msg.sender] = safeAdd(tok_amt[msg.sender], amount);
        tok_users[cnt_tok++]=msg.sender;
        
        //update total amount, ratio
        total_tok += amount;  
        ratio_eth = (total_eth==0)? 0 : total_tok*for_ratio / total_eth;
        ratio_tok = total_eth*for_ratio / total_tok;        
    }


    function exchange(){
        TimetoDeposit = false;

        rest_eth = total_eth;
        rest_tok = total_tok;

        if(ratio_eth<min_ratio){
            ratio_eth = min_ratio;
            ratio_tok = 10**8/ratio_eth;
        } else if(ratio_eth>max_ratio){
            ratio_eth = max_ratio;
            ratio_tok = 10*8/ratio_eth;
        }

        //ether -> token
        i=0;
        while(i<cnt_eth){
            if(rest_tok > 0){ //exchange
                if( (eth_amt[eth_users[i]]*ratio_eth/for_ratio) > rest_tok ){ //send token partly
                    amt_temp = rest_tok*for_ratio/ratio_eth;
                    eth_amt[eth_users[i]] -= amt_temp;
                    if (!Token(token).transfer(tok_users[i], rest_tok)) throw;
                    rest_tok = 0;
                    break;
                } else { //send token
                    amt_send = eth_amt[eth_users[i]];
                    eth_amt[eth_users[i]] = safeSub(eth_amt[eth_users[i]], amt_send);
                    rest_tok = safeSub(rest_tok, amt_send*ratio_eth/for_ratio);
                    amt_send = (amt_send*ratio_eth)/for_ratio;
                    if (!Token(token).transfer(tok_users[i], amt_send)) throw;
                    i++;
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
            if(rest_eth > 0){ //exchange
                if( (tok_amt[tok_users[j]]*ratio_tok/for_ratio) > rest_eth ){ //send ether partly
                    amt_temp = rest_eth*for_ratio/ratio_tok;
                    tok_amt[tok_users[j]] -= amt_temp;
                    if (!tok_users[j].call.value(rest_eth)() ) throw;
                    rest_eth = 0;
                    break;
                } else { //send ether
                    amt_send = tok_amt[tok_users[j]];
                    tok_amt[tok_users[j]] = safeSub(tok_amt[tok_users[j]], amt_send);
                    rest_eth = safeSub(rest_eth, amt_send*ratio_tok/for_ratio);
                    amt_send = (amt_send*ratio_tok)/for_ratio;
                    if (!tok_users[j].call.value(amt_send)()) throw;
                    j++;
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



