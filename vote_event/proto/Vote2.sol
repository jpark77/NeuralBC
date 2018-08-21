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

contract sharedToken{
    using SafeMath for uint256;
    
    mapping(address=>uint256) vote_to;
    mapping(uint256=>uint256) vote_number;
    mapping(uint256=>address) voter;
    mapping(address=>bool) rewarded;
    mapping(address=>bool) voter_voted;
    
    uint256 idx;
    uint256 i;
    uint256 public token_amount;
    uint256 public shared_token;
    uint256 choices;
    uint256 answer;
    uint256 reward_idx;
    
    address creator;
    address _theone=0xee483f46ae158087f7b3350643f0c2beba92cdc8;
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
    
    constructor(address _token,uint _choices,uint _amount_selected){
        creator=msg.sender;
        token=_token;
        choices=_choices;
        token_amount=_amount_selected;
        require(token_amount>0);
        start=false;
        end=false;
    }
    
    function Vote_Start() onlyCreator{
        require(!start);
        start=true;
    }
    
   
    
    function Voting(address _voter,uint _select){
        require(_select<=choices);
        require(_select!=0);
        vote_to[_voter]=_select;
        vote_number[_select]++;
        voter[idx++]=_voter;
        voter_voted[_voter]=true;
    }
    
    function SelectAnswer(uint _answer) onlyCreator{
        require(!answer_selected);
        require(_answer<=choices && _answer!=0);
        answer=_answer;
        answer_selected=true;
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
       
    function GetReward(address _voter) onlyCreator public{
        require(voter_voted[_voter] && !rewarded[_voter]);
        if(vote_to[_voter]==answer){
             require(Theone(_theone).depositVoteReward(address(this), _voter, token, shared_token));
        }
    }
    
    function gettingReward(address _voter,uint256 _amount) onlyTheone public returns (bool){
        require(!rewarded[_voter] && vote_to[_voter]==answer && shared_token==_amount);
        rewarded[_voter]=true;
        return rewarded[_voter];
    }
    /*
    function GiveReward() onlyCreator public{
        require(!reward_given);
        for(i=0;i<idx;i++)
        {
            if(vote_to[voter[i]]==answer){
                rewarded[voter[i]]=true;
                //Contract(address).Deposit(voter[i], token, reward_amount);
             }
        }
        reward_given=true;
    }
    
    function GiveReward2(uint256 _number) onlyCreator public{
        require(!reward_given);
        uint temp_idx=reward_idx;
        for(i=reward_idx; i<idx && i<temp_idx+_number; i++)
        {
            reward_idx=reward_idx.add(1);
            if(vote_to[voter[i]]==answer){
                rewarded[voter[i]]=true;
                //Contract(address).Deposit(voter[i], token, reward_amount);
            }
        }
        if(reward_idx==idx){
            reward_given=true;
        }
    }   */
}


contract Theone{
    function depositVoteReward(address _voting, address _user, address _token, uint256 _amount) public returns (bool) {}
}
