pragma solidity ^0.4.24;

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
    mapping(address=>Voter) Voter_list;
    mapping(uint=>Selection) public Selection_list;
    
    
    
    function Ballot(address _token){
        creator=msg.sender;
        token=_token;
        shared_token=0;
        token_amount=0;
    }
    
    //Making some functions that only the creators can access
    modifier onlyCreator(){
        require(msg.sender == creator);
        _;
    }
    //initializing values
    //choice->the amount of selection
    function initBallot(uint _choice) onlyCreator{
        choice=_choice;
        token_amount=Token(token).balanceOf(address(this));
    }
    
    function Voting(uint _vote_to){
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
    
    /*function CancelVoting(){
        chairperson=msg.sender;
        Voter_list[chairperson].voted=false;
        
    }*/
    
    //_answer->selecting the answer for the question
    //checking the winner
    function Winner_Selection(uint _answer) onlyCreator returns (uint,uint,uint){
        require(_answer<choice);
        answer=_answer;
        shared_token=token_amount/Selection_list[answer].vote_count;
        return (answer, Selection_list[answer].vote_count,shared_token);
    }
    
    //Each voters who selected the answer gets the same amount of reward
    function Share_to_Winner_Voters() onlyCreator{
        shared_token=token_amount/Selection_list[answer].vote_count;
        for(i=0;i<Selection_list[answer].vote_count;i++)
            {
                //Selection_list[winner_index].Voted_By[i]->person getting
                if(!Token(token).transfer(Selection_list[answer].Voted_By[i],shared_token)) revert(); //revert is more efficient than throw for gas consumption
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
