pragma solidity 0.4.24;


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

contract FixedToken{
    using SafeMath for uint256;
    
    mapping(address=>uint256) vote_to;
    mapping(uint256=>uint256) vote_number;
    mapping(uint256=>address) voter;
    mapping(address=>bool) public rewarded;
    mapping(address=>bool) voter_voted;
    uint256 public idx;
    uint256 i;
    uint256 public reward_amount; // fixed
    uint256 public need_amount;
    uint256 choices;
    uint256 answer;
    uint256 reward_idx;
    uint256 limit_voters;
    
    address creator;
    address _theone=0xa55a5892541a67f07f1e4c08035e8ec2c6556656;
    address _rank=0x3e2a3f10c5685c280e06a21d7e12fb6c63f1afcb;
    address token;
    
    bool start;
    bool end;
    
    bool answer_selected;
    bool reward_given;

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
    
    modifier limit(){
        require(idx<limit_voters);
        _;
    }
    
    constructor(address _token,uint _choices,uint _reward_amount,uint _limit_voters) public {
        creator=msg.sender;
        token=_token;
        choices=_choices;
        reward_amount=_reward_amount;
        limit_voters=_limit_voters;
        start=false;
        end=false;
    }
    
    function Vote_Start() onlyCreator public{
        require(!start);
        start=true;
    }

    function Voting(address _voter, uint _select) onGoing limit public{
        require(_select<=choices); 
        require(_select!=0);
        vote_to[_voter]=_select;
        vote_number[_select]++;
        voter[idx++]=_voter;
        voter_voted[_voter]=true;
    }
    
    function SelectAnswer(uint _answer) onlyCreator public{
        require(!answer_selected);
        require(_answer<=choices && _answer!=0);
        answer=_answer;
        answer_selected=true;
        need_amount=reward_amount*vote_number[answer];
    }
    
    /*
    function GetReward(address _voter) onlyCreator public{
        require(voter_voted[_voter] && !rewarded[_voter]);
        if(vote_to[_voter]==answer){
            require(Theone(_theone).depositVoteReward(address(this), _voter, token, reward_amount));
            require(Rank(_rank).plusScore(_voter));
        }
    }
    */
    
    function gettingReward(address _voter, uint256 _amount) onlyTheone public returns (bool){
        require(!rewarded[_voter] && vote_to[_voter]==answer && reward_amount==_amount);
        rewarded[_voter]=true;
        return rewarded[_voter];
    }
    
    /*
    function GiveReward() onlyCreator public{
        require(!reward_given);
        for(i=0;i<idx;i++)
        {
            if(vote_to[voter[i]]==answer){
                //Contract(address).Deposit(voter[i], token, reward_amount);
                require(Rank(_rank).plusScore(voter[i]));
            }
        }
        reward_given=true;
    }
    */
    
     function GiveReward2(uint256 _number) onlyCreator public returns (string){
        if(reward_given){
            return 'done';
        }
        
        uint256 temp_idx=reward_idx;
        for(i=reward_idx; i<idx && i<temp_idx+_number; i++)
        {
            reward_idx=reward_idx.add(1);
            if(vote_to[voter[i]]==answer && voter_voted[voter[i]]){
                require(Theone(_theone).depositVoteReward(address(this), voter[i], token, reward_amount));
                require(Rank(_rank).plusScore(voter[i]));
            }
        }
        if(reward_idx==idx){
            reward_given=true;
            return 'done';
        }
        return 'continue';
    }   
    
}

contract Theone{
    function depositVoteReward(address _voting, address _user, address _token, uint256 _amount) public returns (bool) {}
}

contract Rank{
    function plusScore(address _user) public returns (bool){}
}
