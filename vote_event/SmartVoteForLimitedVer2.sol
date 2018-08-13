pragma solidity 0.4.24;

contract Ballot{
    mapping(address=>uint) vote_to;
    mapping(uint=>uint) vote_number;
    mapping(uint => address) voter;
    
    uint idx;
    uint i;
    uint public token_amount;
    uint public shared_token;
    uint choices;
    uint answer;
    //uint public start;
    
    
    address creator;
    address token;
    
    bool initialized;
    bool selected;
    bool share_sent;
    
    constructor(address _token,uint _choices){
        creator=msg.sender;
        token=_token;
        choices=_choices;
    }
    
    function Vote_Start() onlyCreator{
        require(!initialized);
        token_amount=Token(token).balanceOf(address(this));
        require(token_amount>0);
        initialized=true;
    }
    
    
    modifier onlyCreator(){
        require(msg.sender==creator);
        _;
    }
    //Start Again 2018.08.09
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
        shared_token=token_amount/vote_number[answer];
    }
    
    function ShareToWinners() onlyCreator{
        require(!share_sent);
        for(i=0;i<idx;i++)
        {
            if(vote_to[voter[i]]==answer)
            require(Token(token).transfer(voter[i],shared_token));
        }
        share_sent=true;
    }
    
}

contract Token {
  function balanceOf(address _owner) constant returns (uint256 balance) {}
  function transfer(address _to, uint256 _value) returns (bool success) {}

}
