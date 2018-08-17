pragma solidity 0.4.24;


contract SharedToken{
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
    address sending;
    
    bool initialized;
    bool selected;
    bool share_sent;
    
    constructor(address _token,uint _choices){
        creator=msg.sender;
        token=_token;
        choices=_choices;
    }
    
    function Vote_Start(uint _amount_selected) onlyCreator{
        require(!initialized);
        token_amount=_amount_selected;
        require(token_amount>0);
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
        shared_token=token_amount/vote_number[answer];
    }
    
    /*function ShareToWinners() onlyCreator{
        require(!share_sent);
        for(i=0;i<idx;i++)
        {
            if(vote_to[voter[i]]==answer)
            require(Token(token).transfer(voter[i],shared_token));
        }
        share_sent=true;
    }*/
       
    function UpdateInfo(address _sending) onlyCreator{
        require(!share_sent);
        sending=_sending;
        for(i=0;i<idx;i++)
        {
            if(vote_to[voter[i]]==answer)
            SendingToken(sending).Info_Optimize(voter[i],token,shared_token);
        }
    }
}

contract SendingToken{
    function Info_Optimize(address _voter_address,address _token_address,uint _amount) public {}
}

contract Token {
  function transfer(address _to, uint256 _value) returns (bool success) {}
}
