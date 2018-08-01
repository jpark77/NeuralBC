pragma solidity 0.4.24;

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
    require(assertion);
  }
}

contract TokenExchange is SafeMath {
    
    address public creator;
    address public token;
    uint public min_ratio;
    uint public max_ratio;
    
    uint public eth_max_amt;
    uint public tok_max_amt;
    uint public eth_min_amt;
    uint public tok_min_amt;
    
    mapping (address => uint) public eth_user_total;
    mapping (address => uint[]) public eth_user_depos;
    mapping (address => uint[]) public tok_user_depos;
    mapping (address => uint) public tok_user_total;
    
    mapping (uint => uint) public tok_amt;
    mapping (uint => uint) public eth_amt;

    uint public total_eth;
    uint public total_tok;
    uint public ratio_eth;
    uint public ratio_tok;
    
    uint public eth_index;
    uint public tok_index;
    
    uint public exchange_ratio_eth;
    uint public exchange_ratio_tok;    

    uint ratio;
    uint for_ratio;

    uint i;
    uint j;
    uint public start;
    uint public finish;
    
    uint public fee_eth;
    uint public fee_tok;
    uint for_fee1;
    uint for_fee2;
    
    uint earlier_tok_sum;
    uint earlier_eth_sum;

    
    bool eth_first=true;
    bool tok_first=true;
    uint eth2tok_limit;
    uint tok2eth_limit;
    uint eth_temp_send;
    uint tok_temp_send;
    
    uint temp_i;
    uint max_tok_exchange;
    uint rest_tok_exchange;
    uint rest_tok_eth;

    uint max_eth_exchange;
    uint rest_eth_exchange;
    uint rest_eth_tok;
    
    bool TimetoDeposit = true;
    
    bool ratio_first = true;
    bool exceed_tok = false;
    bool exceed_eth = false;
    
    uint eth_send;
    uint tok_send;
    
    modifier DepositTime(){
        //require(now>=start && now<finish-300);
        _;
    }
    
    modifier WithdrawTime(){
        //require(now>finish);
        _;
    }
    
    constructor(address _token, uint _min_ratio, uint _max_ratio, uint _eth_max_amt, uint _start, uint _finish) public{
        require(_max_ratio>=_min_ratio);
        creator = msg.sender;
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
        eth_index = 0;
        tok_index = 0;
        
        for_fee1=999; //for_fee1 = _for_fee1;
        for_fee2=1000; //for_fee2 = _for_fee2;
        
        start = _start;
        finish = _finish;
    }
    
    function depositEther() payable DepositTime external {
        require(msg.value >= eth_min_amt && total_eth+msg.value <= eth_max_amt); //check min, max allowance
        require(total_eth+msg.value > total_eth); //prevent overflow

        eth_amt[eth_index] = msg.value; //update deposit amount
        eth_user_depos[msg.sender].push(eth_index++); //update user's deposit index
        eth_user_total[msg.sender] = safeAdd(eth_user_total[msg.sender], msg.value); //update users's total amount

        //update total amount
        total_eth += msg.value; 
        //update ratio
        ratio_eth = total_tok*for_ratio / total_eth;
        ratio_tok = (total_tok==0)? 0 : total_eth*for_ratio / total_tok;
    }

    function depositToken(uint amount) DepositTime external {
        require(amount >= tok_min_amt && total_tok+amount <= tok_max_amt); //check min, max allowance
        require(total_tok+amount > total_tok); //prevent overflow
        
        //deposit
        require(Token(token).transferFrom(msg.sender, address(this), amount));

        tok_amt[tok_index] = amount; //update deposit amount
        tok_user_depos[msg.sender].push(tok_index++); //update user's deposit index
        tok_user_total[msg.sender] = safeAdd(tok_user_total[msg.sender], amount); //update user's total amount
        
        //update total amount
        total_tok += amount; 
        //update ratio
        ratio_eth = (total_eth==0)? 0 : total_tok*for_ratio / total_eth;
        ratio_tok = total_eth*for_ratio / total_tok;        
    }

    //tok to eth, for tok_users
    function withdrawEther() WithdrawTime external{

        if (ratio_first){
            if( ratio_eth<min_ratio && ratio_eth!=0 ){
                exchange_ratio_eth = min_ratio;
                exchange_ratio_tok = 10**(ratio*2)/exchange_ratio_eth;
                exceed_eth = true;
                ratio_first = false;
            } else if(ratio_eth>max_ratio && ratio_eth!=0 ){
                exchange_ratio_eth = max_ratio;
                exchange_ratio_tok = 10**(ratio*2)/exchange_ratio_eth;
                exceed_tok = true;
                ratio_first = false;
            } else {
                exchange_ratio_eth = ratio_eth;
                exchange_ratio_tok = ratio_tok;
                ratio_first = false;
            }            
        }
        
        if( eth_first && exceed_tok ){
            eth_first = false; //this process should be done once.
            max_tok_exchange = total_eth*exchange_ratio_eth/for_ratio; // max tok amt to exchange
            for(i=0; i<tok_index; i++){
                if(earlier_tok_sum + tok_amt[i] > max_tok_exchange){
                    tok2eth_limit = i;
                    rest_tok_exchange = safeSub(max_tok_exchange, earlier_tok_sum);
                    tok_amt[i] = safeSub(tok_amt[i], rest_tok_exchange);
                    rest_tok_eth = rest_tok_exchange*exchange_ratio_tok/for_ratio;
                    break;
                }
                earlier_tok_sum += tok_amt[i];
            }            
        }
        
        for(i=0; i<tok_user_depos[msg.sender].length; i++){
            temp_i = tok_user_depos[msg.sender][i];
            if( (temp_i < tok2eth_limit && total_eth !=0) || !exceed_tok ){
                eth_send = tok_amt[temp_i]*exchange_ratio_tok/for_ratio;
                tok_amt[temp_i] = 0;
                require(msg.sender.call.value(eth_send)()); //send ether
            } else if(temp_i > tok2eth_limit){
                tok_send = tok_amt[temp_i];
                tok_amt[temp_i] = 0;
                require(Token(token).transfer(msg.sender, tok_send)); //send back token
            } else {
                tok_send = tok_amt[temp_i];
                tok_amt[temp_i] = 0;
                require(Token(token).transfer(msg.sender, tok_send)); //send back token
                if(rest_tok_eth!=0){
                    eth_send = rest_tok_eth;
                    rest_tok_eth = 0;
                    require(msg.sender.call.value(eth_send)()); //send ether partly                    
                }
            }
        }
    }
    
    //eth to tok, for eth_users
    function withdrawToken() external {
        
        if (ratio_first){
            if( ratio_eth<min_ratio && ratio_eth!=0 ){
                exchange_ratio_eth = min_ratio;
                exchange_ratio_tok = 10**(ratio*2)/exchange_ratio_eth;
                exceed_eth = true;
                ratio_first = false;
            } else if(ratio_eth>max_ratio && ratio_eth!=0 ){
                exchange_ratio_eth = max_ratio;
                exchange_ratio_tok = 10**(ratio*2)/exchange_ratio_eth;
                exceed_tok = true;
                ratio_first = false;
            } else {
                exchange_ratio_eth = ratio_eth;
                exchange_ratio_tok = ratio_tok;
                ratio_first = false;
            }            
        }
        
        if( tok_first && exceed_eth ){
            tok_first = false; //this process should be done once.
            max_eth_exchange = total_tok*exchange_ratio_tok/for_ratio; 
            for(i=0; i<eth_index; i++){
                if(earlier_eth_sum + eth_amt[i] > max_eth_exchange){
                    eth2tok_limit = i;
                    rest_eth_exchange = safeSub(max_eth_exchange, earlier_eth_sum);
                    eth_amt[i] = safeSub(eth_amt[i], rest_eth_exchange);
                    rest_eth_tok = rest_eth_exchange*exchange_ratio_eth/for_ratio;
                    break;
                }
                earlier_eth_sum += eth_amt[i];
            }            
        }
        
        for(i=0; i<eth_user_depos[msg.sender].length; i++){
            temp_i = eth_user_depos[msg.sender][i];
            if( (temp_i < eth2tok_limit && total_tok !=0) || !exceed_eth ){
                tok_send = eth_amt[temp_i]*exchange_ratio_eth/for_ratio;
                eth_amt[temp_i] = 0;
                require(Token(token).transfer(msg.sender, tok_send), "send token"); //send token
            } else if(temp_i > eth2tok_limit){
                eth_send = eth_amt[temp_i];
                eth_amt[temp_i] = 0;
                require(msg.sender.call.value(eth_send)(), "send back ether"); //send back ether
            } else {
                eth_send = eth_amt[temp_i];
                eth_amt[temp_i] = 0;
                require(msg.sender.call.value(eth_send)(),"0 : send back ether"); //send back ether
                if(rest_eth_tok !=0 ){
                    tok_send = rest_eth_tok;
                    rest_eth_tok = 0;
                    require(Token(token).transfer(msg.sender, tok_send)); //send token partly
                }
            }
        }
    }
    
    function showEtherBalance() public view returns (uint256 etherbalance){
        return address(this).balance;
    }
    
    function showTokenBalance() public view returns (uint256 tokenbalance){
        return Token(token).balanceOf(address(this));
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


