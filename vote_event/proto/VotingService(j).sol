pragma solidity ^0.4.24;

library SafeMath {

  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
      if (_a == 0) {
          return 0;
        }
      uint256 c = _a * _b;
      assert(c / _a == _b);
      return c;
      
  }

  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
      require(_b > 0);
      uint256 c = _a / _b;
      return c;
  }

  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
      assert(_b <= _a);
      uint256 c = _a - _b;
      return c;
  }

  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
      uint256 c = _a + _b;
      assert(c >= _a);
      return c;
  }
}

contract VotingService{
    using SafeMath for uint256;
    
    address creator;
    address _theone;
    address token;
    
    bool start;
    bool end;
    
    bool answer_selected;
    
    string token_name;
    
    uint256 public shared_token;
    uint256 public token_amount;
    uint256 public amount_selected;
    uint256 choices;
    uint256 answer;
    
    mapping(address=>uint256) vote_to;
    mapping(uint256=>uint256) vote_number;
    mapping(address=>bool) voter_voted;
    mapping(address=>uint256) voted_time;
    mapping(address=>bool) rewarded;
    mapping(address=>uint256) public voter_point;
    
    modifier onlyCreator(){
        require(msg.sender==creator);
        _;
    }
    
    modifier beforeStart(){
        require(!start);
        _;
    }
    
    modifier onGoing(){
        require(start && !end);
        _;
    }
    
    modifier afterFinish(){
        require(end);
        _;
    }
    
    modifier onlyTheone(){
        require(msg.sender==_theone);
        _;
    }
    
    constructor(address _token,uint _choices,uint _amount_selected,string _token_name) public{
        creator=msg.sender;
        token=_token;
        choices=_choices;
        amount_selected=_amount_selected;
        require(amount_selected>0);
        start=false;
        end=false;
        token_name=_token_name;
    }
    
    function Vote_Start() onlyCreator{
        require(!start);
        token_amount=Token(token).balanceOf(address(this));
        require(amount_selected*(10**18)==token_amount);
        start=true;
    }
    
    event voting(address _voter,uint256 _vote_time,uint256 _point,string _gate);
    
    function Voting(address _voter,uint256 _vote_time,uint256 _select) onGoing public{
        require(!voter_voted[_voter]);
        require(_select<=choices);
        require(_select!=0);
        vote_to[_voter]=_select;
        vote_number[_select]++;
        voter_voted[_voter]=true;
        voter_point[_voter]=voter_point[_voter].add(1);
        voting(_voter,_vote_time,1,"Participation");
    }
    
    event selectanswer(uint256 _answer,bool _answer_selected);
    
    function SelectAnswer(uint256 _answer) onlyCreator onGoing{
        require(!answer_selected);
        require(_answer<=choices && _answer!=0);
        answer=_answer;
        answer_selected=true;
        shared_token=token_amount/vote_number[answer];
        end=true;
        selectanswer(_answer,answer_selected);
    }
    
    event givereward(address _reward_voter,uint256 _reward_time,uint256 _point,string _token_name,uint256 _shared_token,string _gate);
    
    function GiveReward(address _reward_voter,uint256 _reward_time) onlyCreator afterFinish{
        rewarded[_reward_voter]=true;
        require(Token(token).transfer(_reward_voter,shared_token));
        voter_point[_reward_voter]=voter_point[_reward_voter].add(5);
        givereward(_reward_voter,_reward_time,5,token_name,shared_token,"Answer");
    }
    
    
}

contract Token {
  function balanceOf(address _owner) constant returns (uint256 balance) {}
  function transfer(address _to, uint256 _value) returns (bool success) {}
}
