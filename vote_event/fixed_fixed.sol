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

    uint256 idx;
    uint256 i;
    uint256 public reward_amount; // fixed
    uint256 public need_amount;
    uint256 choices;
    uint256 answer;
    uint256 temp_idx;
    
    address creator;
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
    
    constructor(address _token,uint _choices,uint _reward_amount) public {
        creator=msg.sender;
        token=_token;
        choices=_choices;
        reward_amount=_reward_amount;
        start=false;
        end=false;
    }
    
    function Vote_Start() onlyCreator public{
        require(!start);
        start=true;
    }

    function Voting(address _voter, uint _select) onGoing public{
        require(_select<=choices); 
        require(_select!=0);
        vote_to[_voter]=_select;
        vote_number[_select]++;
        voter[idx++]=_voter;
    }
    
    function SelectAnswer(uint _answer) onlyCreator public{
        require(!answer_selected);
        require(_answer<=choices && _answer!=0);
        answer=_answer;
        answer_selected=true;
        need_amount=reward_amount*vote_number[answer];
    }
    
    
    function GiveReward() onlyCreator public{
        require(!reward_given);
        for(i=0;i<idx;i++)
        {
            if(vote_to[voter[i]]==answer){
                //Contract(address).Deposit(voter[i], token, reward_amount);

            }
        }
        reward_given=true;
    }
    
    function GiveReward2(uint256 _number) onlyCreator public{
        require(!reward_given);
        for(i=temp_idx; i<idx && i<idx+_number; i++)
        {
            if(vote_to[voter[i]]==answer){
                temp_idx=temp_idx.add(1);
                //Contract(address).Deposit(voter[i], token, reward_amount);
            }
        }
        if(temp_idx==idx){
            reward_given=true;
        }
    }
    
}

