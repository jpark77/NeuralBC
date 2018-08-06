pragma solidity 0.4.24;

contract SafeMath {
  function safeMul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    if (_a == 0) {
      return 0;
    }
    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }
  function safeSub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }
  function safeAdd(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract Exchange is SafeMath{
    address neuralBC;
    address public token;
    uint256 public min_ratio;
    uint256 public max_ratio;
    uint256 eth_deposit_ratio;
    uint256 tok_deposit_ratio;
    uint256 public eth_withdraw_ratio;
    uint256 public tok_withdraw_ratio;
    uint256 public min_deposit_eth;
    uint256 public min_deposit_tok;
    uint256 public max_deposit_eth;
    uint256 public max_deposit_tok;
    uint256 public total_eth;
    uint256 public total_tok;
    uint256 public ratio_eth;
    uint256 public ratio_tok;
    uint for_ratio;

    uint256 public eth_idx;
    mapping(uint256=>uint256) public eth_amt;
    mapping(address=>mapping(uint256=>uint256)) public eth_deposit_idx; // equal to eth_idx
    mapping(address=>uint256) public eth_deposit_len; // address's deposit length

    uint256 public tok_idx;
    mapping(uint=>uint) public tok_amt;
    mapping(address=>mapping(uint256=>uint256)) public tok_deposit_idx;
    mapping(address=>uint256) public tok_deposit_len;

    uint256 exchange_total_eth;
    uint256 exchange_total_tok;
    bool public firstWithdraw;
    bool public firstEth;
    bool public firstTok;
    bool public calcfinish;
    bool public eth_excess;
    bool public tok_excess;
    bool public exchange_null;
    bool public firstGas;
    uint256 e2t_limit;
    uint256 t2e_limit;
    uint256 max_e2t_tok;
    uint256 max_t2e_tok;
    
    uint eth_send;
    uint tok_send;
    uint eth_back;
    uint tok_back;
    
    uint partly_e2t;
    uint partly_t2e;
    
    uint fee_unit;
    uint user_take;
    uint fee;
    uint public fee_eth;
    uint public fee_tok;
    
    uint start;
    uint finish;
    
    uint temp;
    uint gas_first;
    uint gas_last;
    uint public gas_back;
    uint public gas_cost;
    uint public gas_final;
    uint public gas_e2t;
    uint public gas_e2t_1;
    uint public gas_e2t_2;
    
    event Deposit_Ether(address user, uint amount);
    event Deposit_Token(address token, address user, uint amount);
    event Withdraw_Token(address token, address user, uint amount);
    event Withdraw_Ether(address user, uint amount);
    event Sendback_Token(address token, address user, uint amount);
    event Sendback_Ether(address user, uint amount);
    
    modifier DepositTime(){
        //require(now>=start && now<finish-300);
        _;
    }
    
    modifier WithdrawTime(){
        //require(now>finish);
        require( (firstWithdraw&&firstEth&&firstTok) || calcfinish==true );
        _;
    }
    
    constructor(address _token,uint256 _min_ratio,uint256 _max_ratio,uint256 _max_deposit_eth,uint _start, uint _finish) public{
        require(_min_ratio<=_max_ratio);
        for_ratio=10000;
        
        neuralBC=0x5156169a977B0f798a17791b8Dbf287EF4857f41; //neuralBC=_neuralBC
        token=_token;
        min_ratio=_min_ratio;
        max_ratio=_max_ratio;
        max_deposit_eth=_max_deposit_eth;
        max_deposit_tok=safeMul(max_deposit_eth,max_ratio)/for_ratio;
        min_deposit_eth=10**18;
        min_deposit_tok=safeMul(min_deposit_eth,min_ratio)/for_ratio;

        firstWithdraw=true;
        firstEth=true;
        firstTok=true;
        firstGas=true;
        eth_excess=false;
        tok_excess=false;
        exchange_null=false;
        calcfinish=false;
        
        fee_unit=1000;
        user_take=999;
        fee=fee_unit-user_take;
        
        start=_start;
        finish=_finish;
    }
    
    function() {
        revert();
    }
    
    function DepositEther() payable DepositTime external{
        require(msg.value >= min_deposit_eth && total_eth+msg.value <= max_deposit_eth); //check min, max allowance
        //require(total_eth+msg.value > total_eth); //prevent overflow        
    
        eth_amt[eth_idx]=msg.value;
        eth_deposit_idx[msg.sender][eth_deposit_len[msg.sender]++]=eth_idx++;
        //update info(total, ratio)
        total_eth=safeAdd(total_eth,msg.value);
        ratio_eth=safeMul(total_tok,for_ratio)/total_eth;
        ratio_tok=(total_tok==0)? 0:safeMul(total_eth,for_ratio)/total_tok;
        emit Deposit_Ether(msg.sender, msg.value);
    }
    
    function DepositToken(uint256 amount) DepositTime external{
        require(amount >= min_deposit_tok && total_tok+amount <= max_deposit_tok); //check min, max allowance
        //require(total_tok+amount > total_tok); //prevent overflow
        
        require(Token(token).transferFrom(msg.sender, address(this), amount));
        tok_amt[tok_idx]=amount;
        tok_deposit_idx[msg.sender][tok_deposit_len[msg.sender]++]=tok_idx++;
        //update info(total, ratio)
        total_tok=safeAdd(total_tok,amount);
        ratio_eth = (total_eth==0)? 0:safeMul(total_tok,for_ratio)/total_eth;
        ratio_tok = safeMul(total_eth,for_ratio)/total_tok;     
        emit Deposit_Token(token, msg.sender, amount);

    }
    
    function Withdraw() WithdrawTime external{
        uint i;
        uint idx;
        
        gas_first=gasleft();
        //calculate ratio
        if(firstWithdraw){
            firstWithdraw=false;
            if(total_eth==0 || total_tok==0){
                eth_withdraw_ratio=0;
                tok_withdraw_ratio=0;
                exchange_total_eth=0;
                exchange_total_tok=0;
                exchange_null=true;
            }else if(safeMul(total_eth,min_ratio)>safeMul(total_tok,for_ratio)){ //eth excess
                eth_withdraw_ratio=min_ratio;
                tok_withdraw_ratio=safeMul(for_ratio,for_ratio)/eth_withdraw_ratio;
                exchange_total_tok=total_tok;
                exchange_total_eth=safeMul(exchange_total_tok,tok_withdraw_ratio)/for_ratio;
                eth_excess=true;
            }else if(safeMul(total_eth,max_ratio)<safeMul(total_tok,for_ratio)){ //tok excess
                eth_withdraw_ratio=max_ratio;
                tok_withdraw_ratio=safeMul(for_ratio,for_ratio)/eth_withdraw_ratio;
                exchange_total_eth=total_eth;
                exchange_total_tok=safeMul(exchange_total_eth,eth_withdraw_ratio)/for_ratio;
                tok_excess=true;
            }else{ //in range
                eth_withdraw_ratio=ratio_eth;
                tok_withdraw_ratio=ratio_tok;
                exchange_total_eth=total_eth;
                exchange_total_tok=total_tok;
            }
            //calculate fee
            if(!exchange_null){
                fee_eth = safeMul(exchange_total_eth,fee)/fee_unit;
                fee_tok = safeMul(exchange_total_tok,fee)/fee_unit;
                //send eth_fee
                temp=fee_eth;
                fee_eth=0;
                require(neuralBC.call.value(temp)());
                //send tok_fee
                temp=fee_tok;
                fee_tok=0;
                require(Token(token).transfer(neuralBC, temp));                
            }
        }
        
        //calculate e2t limit
        if(firstEth&&eth_excess){
            uint256 prev_eth_sum;
            for(i=0;i<eth_idx;i++){
                if(safeAdd(prev_eth_sum,eth_amt[i])>exchange_total_eth){
                    e2t_limit=i;
                    partly_e2t=safeSub(exchange_total_eth,prev_eth_sum);
                    eth_amt[i]=safeSub(eth_amt[i],partly_e2t);
                    break;
                }
                prev_eth_sum=safeAdd(prev_eth_sum,eth_amt[i]);
            }
            firstEth=false;
        }

        //calculate t2e limit
        if(firstTok&&tok_excess){
            uint256 prev_tok_sum;
            for(i=0;i<tok_idx;i++){
                if(safeAdd(prev_tok_sum,tok_amt[i])>exchange_total_tok){
                    t2e_limit=i;
                    partly_t2e=safeSub(exchange_total_tok,prev_tok_sum);
                    tok_amt[i]=safeSub(tok_amt[i],partly_t2e);
                    break;
                }
                prev_tok_sum=safeAdd(prev_tok_sum,tok_amt[i]);
            }
            firstTok=false;
        }
        calcfinish=true;
    
        gas_last=gasleft();
        gas_cost=safeSub(gas_first, gas_last);

        if(firstGas){
            firstGas=false;
            gas_back = safeMul(tx.gasprice,gas_cost);
            //require(msg.sender.call.value(gas_back);
        }

        //ether to token
        for(i=0;i<eth_deposit_len[msg.sender];i++){
            idx=eth_deposit_idx[msg.sender][i];
            if( (idx<e2t_limit||!eth_excess) && exchange_null==false){
                tok_send=safeMul(safeMul(eth_amt[eth_deposit_idx[msg.sender][i]],eth_withdraw_ratio)/for_ratio,user_take)/fee_unit;
                eth_amt[eth_deposit_idx[msg.sender][i]]=0;
                require(Token(token).transfer(msg.sender,tok_send)); //send token
                emit Withdraw_Token(token, msg.sender, tok_send);
            }else if(idx>t2e_limit){ 
                eth_back=eth_amt[eth_deposit_idx[msg.sender][i]];
                eth_amt[eth_deposit_idx[msg.sender][i]]=0;
                require(msg.sender.call.value(eth_back)()); //send back ether
                emit Sendback_Ether(msg.sender, eth_back);
            }else{ 
                eth_back=eth_amt[eth_deposit_idx[msg.sender][i]];
                eth_amt[eth_deposit_idx[msg.sender][i]]=0;
                require(msg.sender.call.value(eth_back)()); //send back ether
                emit Sendback_Ether(msg.sender, eth_back);
                if(partly_e2t!=0){
                    tok_send=safeMul(safeMul(partly_e2t,eth_withdraw_ratio)/for_ratio,user_take)/fee_unit;
                    partly_e2t=0;
                    require(Token(token).transfer(msg.sender, tok_send)); //send token partly
                    emit Withdraw_Token(token, msg.sender, tok_send);
                }
            }
        }

        
        //token to ether
        for(i=0;i<tok_deposit_len[msg.sender];i++){
            idx=eth_deposit_idx[msg.sender][i];
            if( (idx<t2e_limit||!tok_excess) && exchange_null==false){
                eth_send=safeMul(safeMul(tok_amt[tok_deposit_idx[msg.sender][i]],tok_withdraw_ratio)/for_ratio,user_take)/fee_unit;
                tok_amt[tok_deposit_idx[msg.sender][i]]=0;
                require(msg.sender.call.value(eth_send)()); //send ether
                emit Withdraw_Ether(msg.sender, eth_send);
            }else if(idx>t2e_limit){ 
                tok_back=tok_amt[tok_deposit_idx[msg.sender][i]];
                tok_amt[tok_deposit_idx[msg.sender][i]]=0;
                require(Token(token).transfer(msg.sender, tok_back)); //send back token
                emit Sendback_Token(token, msg.sender, eth_back);
            }else{ 
                tok_back=tok_amt[tok_deposit_idx[msg.sender][i]];
                tok_amt[tok_deposit_idx[msg.sender][i]]=0;
                require(Token(token).transfer(msg.sender, tok_back)); //send back token
                emit Sendback_Token(token, msg.sender, eth_back);
                if(partly_t2e!=0){
                    eth_send=safeMul(safeMul(partly_t2e,tok_withdraw_ratio)/for_ratio,user_take)/fee_unit;
                    partly_t2e=0;
                    require(msg.sender.call.value(eth_send)()); //send ether patly
                    emit Withdraw_Ether(msg.sender, eth_send);
                }
            }
        }
        gas_final=gasleft();
    }
    
    function balance_eth() public view returns (uint amount){
        return address(this).balance;
    }

    function balance_tok() public view returns (uint256 amount){
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
