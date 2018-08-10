pragma solidity 0.4.24;

contract Ballot{
    mapping(address=>uint) vote_to;
    mapping(uint=>uint) vote_number;
    mapping(uint=>address) voter;
    
    uint idx;
    uint i;
    uint public fixed_amount;
    uint public need_amount;
    uint public storaged_amount;
    uint choices;
    uint answer;
    
    address creator;
    address token;
    
    bool initialized;
    bool selected;
    bool token_sent;
    
    constructor(address _token,uint _choices,uint _fixed_amount){
        creator=msg.sender;
        token=_token;
        choices=_choices;
        fixed_amount=_fixed_amount;
    }
    
    function Vote_Start() onlyCreator{
        require(!initialized);
        initialized=true;
    }
    
    modifier onlyCreator(){
        require(msg.sender==creator);
        _;
    }
    
    function Voting(uint _vote_to){
        require(_vote_to<=choices);
        require(_vote_to!=0);
        vote_to[msg.sender]=_vote_to;
        vote_number[_vote_to]++;
        voter[idx++]=msg.sender;
    }
    
    function AnswerSelected(uint _answer) onlyCreator{
        require(!selected);
        require(_answer<=choices && _answer!=0);
        answer=_answer;
        selected=true;
        need_amount=fixed_amount*vote_number[answer];
    }
    
    function CheckStoraged() onlyCreator(){
        storaged_amount=Token(token).balanceOf(address(this));
    }
    
    function ShareToWinners() onlyCreator{
        storaged_amount=Token(token).balanceOf(address(this));
        require(need_amount*(10**18)==storaged_amount);
        require(!token_sent);
        for(i=0;i<idx;i++)
        {
            if(vote_to[voter[i]]==answer)
            require(Token(token).transfer(voter[i],fixed_amount*(10**18)));
        }
        token_sent=true;
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
