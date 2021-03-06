pragma solidity 0.4.24;

contract Ballot{
    struct Voter{
        bool voted;
        uint vote_to;
    }
    
    struct Selection{
        uint vote_count;
        mapping(uint=>address) Voted_By;
    }
    address token;
    address chairperson;
    address creator;
    
    uint i;
    uint public token_amount;
    uint shared_token;
    uint choice;
    uint answer;
    uint end;
    uint public start;
    uint find_index;
    
    bool initialized;
    bool winner_selected;
    bool share_sent;
    mapping(address=>Voter) Voter_list;
    mapping(uint=>Selection) public Selection_list;
    
    
    function Ballot(address _token){
        creator=msg.sender;
        token=_token;
        shared_token=0;
        token_amount=0;
        winner_selected=false;
        share_sent=false;
        initialized=false;
    }
    
    //Making some functions that only the creators can access
    modifier onlyCreator(){
        require(msg.sender == creator);
        _;
    }
    
    //initializing values
    //choice->the amount of selection
    //setting the limited time for voting
    function initBallot(uint _choice,uint _limitedtime) onlyCreator{
        require(!initialized);
        choice=_choice;
        token_amount=Token(token).balanceOf(address(this));
        require(token_amount>0,"No token deposited");
        initialized=true;
        start=now;
        end=now+_limitedtime;
        
    }
    
    function VotingSystem(uint _vote_to){
        require(now<end);
        chairperson=msg.sender;
        require(Voter_list[chairperson].vote_to!=_vote_to);
        if(!Voter_list[chairperson].voted)
            Voting(_vote_to);
        else
            ChangeVoting(_vote_to);
    }
    
    //after the limited time exceeds you cannot vote
    function Voting(uint _vote_to) internal{
        //require(now<end);
        require(_vote_to<=choice-1);  
        chairperson=msg.sender;
        require(!Voter_list[chairperson].voted);
        Voter_list[chairperson].voted=true;
        Voter_list[chairperson].vote_to=_vote_to;
        //require(Voter_list[chairperson].vote_to==_vote_to);
        uint temp=Selection_list[Voter_list[chairperson].vote_to].vote_count;
        Selection_list[Voter_list[chairperson].vote_to].Voted_By[temp]=chairperson;
        Selection_list[Voter_list[chairperson].vote_to].vote_count++;
    }
    
    
    //If the voter wants to change his mind
    function ChangeVoting(uint _vote_to) internal{
        //require(now<end); 
        chairperson=msg.sender;
        require(Voter_list[chairperson].voted);
        for(i=0;i<Selection_list[Voter_list[chairperson].vote_to].vote_count-1;i++)
        {
            if(Selection_list[Voter_list[chairperson].vote_to].Voted_By[i]==chairperson)
            {
                find_index=i;
                break;
            }
        }
        require(find_index<Selection_list[Voter_list[chairperson].vote_to].vote_count);
        for(i=find_index;i<Selection_list[Voter_list[chairperson].vote_to].vote_count-1;i++)
            Selection_list[Voter_list[chairperson].vote_to].Voted_By[i]=Selection_list[Voter_list[chairperson].vote_to].Voted_By[i+1];
        delete Selection_list[Voter_list[chairperson].vote_to].Voted_By[i];
        
        Voter_list[chairperson].voted=false;
        Selection_list[Voter_list[chairperson].vote_to].vote_count--;
        Voter_list[chairperson].voted=true;
        Voter_list[chairperson].vote_to=_vote_to;
        uint temp=Selection_list[Voter_list[chairperson].vote_to].vote_count;
        Selection_list[Voter_list[chairperson].vote_to].Voted_By[temp]=chairperson;
        Selection_list[Voter_list[chairperson].vote_to].vote_count++;
    }
    
    //_answer->selecting the answer for the question
    //checking the winner
    function Winner_Selection(uint _answer) onlyCreator{
        require(now>end);
        require(!winner_selected);
        require(_answer<choice);
        answer=_answer;
        winner_selected=true;
        shared_token=token_amount/Selection_list[answer].vote_count;
    }
    
    
    function Winner_Selection_Check() view returns(uint,uint,uint,uint){
        return (answer, Selection_list[answer].vote_count,token_amount,shared_token);
    }
    
    //Each voters who selected the answer gets the same amount of reward
    function Share_to_Winner_Voters() onlyCreator{
        require(!share_sent);
        require(now>end);
        shared_token=token_amount/Selection_list[answer].vote_count;
        for(i=0;i<Selection_list[answer].vote_count;i++)
            {
                //Selection_list[winner_index].Voted_By[i]->person getting
                require(Token(token).transfer(Selection_list[answer].Voted_By[i],shared_token)); 
            }
        share_sent=true;
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
