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
    
    mapping (address => mapping(uint => uint) ) public eth_user_index;
    mapping (address => mapping(uint => uint) ) public tok_user_index;
    mapping (uint => address) public eth_users;
    mapping (uint => address) public tok_users;
    mapping (address => uint) public eth_user_total;
    mapping (address => uint) public tok_user_total;

    uint public total_eth;
    uint public total_tok;
    uint public rest_eth;
    uint public rest_tok;
    uint public ratio_eth;
    uint public ratio_tok;
    
    uint public eth_index;
    uint public tok_index;
    uint amt_get;
    uint amt_send;
    uint amt_temp;

    uint ratio;
    uint for_ratio;

    uint i;
    uint j;
    uint public start;
    uint public finish;
    
    uint fee_eth;
    uint fee_tok;
    
    bool TimetoDeposit = true;
    
    function(){
        throw;
    }
    
    function TokenExchange(address _token, uint _min_ratio, uint _max_ratio, uint _eth_max_amt, uint _start, uint _finish){
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
        eth_index = 0;
        tok_index = 0;
        
        //start = _start;
        //finish = _finish;
    }
    
    function depositEther() payable public {
        require(TimetoDeposit);
        
        //require(now>=start && now<finish);
        require(msg.value >= eth_min_amt); //check min allowance
        require(total_eth+msg.value <= eth_max_amt); //check max allowance
        require(total_eth+msg.value > total_eth); //prevent overflow
        
        //update index's user, index's amount, user's total amount
        eth_user_total[msg.sender] = safeAdd(eth_user_total[msg.sender], msg.value); //update users's total amount
        eth_user_index[msg.sender][eth_index] = msg.value; //update user, 
        eth_users[eth_index++] = msg.sender; //update index
        
        //update total amount, ratio
        total_eth += msg.value;
        
        ratio_eth = total_tok*for_ratio / total_eth;
        ratio_tok = (total_tok==0)? 0 : total_eth*for_ratio / total_tok;
    }

    function depositToken(uint amount) external {
        require(TimetoDeposit);
        //require(now>=start && now<finish);
        require(amount >= tok_min_amt); //check min allowance
        require(total_tok+amount <= tok_max_amt); //check max allowance
        require(total_tok+amount > total_tok); //prevent overflow
        
        //deposit
        if (!Token(token).transferFrom(msg.sender, address(this), amount)) throw;
        //update user, users's amount
        tok_user_total[msg.sender] = safeAdd(tok_user_total[msg.sender], amount); //update user's total amount
        tok_user_index[msg.sender][tok_index] = amount;
        tok_users[tok_index++]=msg.sender; //update user
        
        //update total amount, ratio
        total_tok += amount;  
        ratio_eth = (total_eth==0)? 0 : total_tok*for_ratio / total_eth;
        ratio_tok = total_eth*for_ratio / total_tok;        
    }


    function exchange() external{
        //require(now>finish);

        rest_eth = total_eth;
        rest_tok = total_tok;

        if(ratio_eth<min_ratio){
            ratio_eth = min_ratio;
            ratio_tok = 10**8/ratio_eth;
        } else if(ratio_eth>max_ratio){
            ratio_eth = max_ratio;
            ratio_tok = 10**8/ratio_eth;
        }

        //ether -> token
        i=0;
        while(i<eth_index){
            if(rest_tok > 0){ //exchange
                if( (eth_user_index[eth_users[i]][i]*ratio_eth/for_ratio) > rest_tok ){ //send token partly
                    amt_temp = rest_tok*for_ratio/ratio_eth;
                    eth_user_index[eth_users[i]][i] -= amt_temp;
                    if (!Token(token).transfer(eth_users[i], rest_tok)) throw;
                    rest_tok = 0;
                    break;
                } else { //send token
                    amt_send = eth_user_index[eth_users[i]][i];
                    eth_user_index[eth_users[i]][i] = safeSub(eth_user_index[eth_users[i]][i], amt_send);
                    rest_tok = safeSub(rest_tok, amt_send*ratio_eth/for_ratio);
                    amt_send = (amt_send*ratio_eth)/for_ratio;
                    if (!Token(token).transfer(eth_users[i], amt_send)) throw;
                    i++;
                }
            } else {
                break;
            }
        }
        while(i<eth_index){ //send back ether
            if (!eth_users[i].call.value(eth_user_index[eth_users[i]][i])()) throw;
            i++;
        }
        
        //token -> ether
        j=0;
        while(j<tok_index){
            if(rest_eth > 0){ //exchange
                if( (tok_user_index[tok_users[j]][j]*ratio_tok/for_ratio) > rest_eth ){ //send ether partly
                    amt_temp = rest_eth*for_ratio/ratio_tok;
                    tok_user_index[tok_users[j]][j] -= amt_temp;
                    if (!tok_users[j].call.value(rest_eth)() ) throw;
                    rest_eth = 0;
                    break;
                } else { //send ether
                    amt_send = tok_user_index[tok_users[j]][j];
                    tok_user_index[tok_users[j]][j] = safeSub(tok_user_index[tok_users[j]][j], amt_send);
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
        while(j<tok_index){ //send back token
            amt_send = tok_user_index[tok_users[j]][j];
            tok_user_index[tok_users[j]][j] = safeSub(tok_user_index[tok_users[j]][j], amt_send);



