pragma solidity 0.4.24;

contract FixedToken{
    mapping(address=>uint) vote_to;
    mapping(uint=>uint) vote_number;
    mapping(uint=>address) voter;
    
    uint idx;
    uint i;
    uint public fixed_amount;
    uint public need_amount;
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
    
    function Voting(uint _vote_to,address _voter_add){
        require(_vote_to<=choices); 
        require(_vote_to!=0);
        vote_to[_voter_add]=_vote_to;
        vote_number[_vote_to]++;
        voter[idx++]=_voter_add;
    }
    
    function AnswerSelected(uint _answer) onlyCreator{
        require(!selected);
        require(_answer<=choices && _answer!=0);
        answer=_answer;
        selected=true;
        need_amount=fixed_amount*vote_number[answer];
    }
    
    
    function ShareToWinners() onlyCreator{
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
  function transfer(address _to, uint256 _value) returns (bool success) {}
  
}
