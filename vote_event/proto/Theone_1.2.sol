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

contract Theone{
    using SafeMath for uint256;

    address owner;
    
    mapping(address => mapping(address => uint256) ) public token_amounts;
 
    mapping(address => address[]) public token_list;
    mapping(address => bool) public valid_vote;
    mapping(address => mapping(address => bool) ) givenReward;
    
    mapping(address => mapping(address => bool) ) registeredToken;
    mapping(address => bool) allToken;
    
    address[] public allTokenList;
    
    modifier onlyOwner(){
        require(msg.sender==owner);
        _;
    }
    
    modifier onlyValidVote(){
        require(valid_vote[msg.sender]);
        _;
    }
    
    constructor() public{
        owner = msg.sender;
    }
    
    function validateVote(address _voting) public onlyOwner{
        valid_vote[_voting]=true;
    }
    
    function depositVoteReward(address _voting, address _user, address _token, uint256 _amount) onlyValidVote public returns (bool){
        require(valid_vote[_voting] && !givenReward[_voting][_user]);
        givenReward[_voting][_user]=true;
        require(!Voting(_voting).rewarded(_user));
        require(Voting(_voting).gettingReward(_user, _amount));
        token_amounts[_user][_token] = token_amounts[_user][_token].add(_amount);
        
        plusUserToken(_user, _token);
        return true;
    }
    
    
    function withdrawVoteReward(address _user, address _token, uint256 _amount) public returns (bool){
        token_amounts[_user][_token] = token_amounts[_user][_token].sub(_amount);
        return true;
    }
    
    function plusToken(address _token) public {
        if(!allToken[_token]){
            allTokenList.push(_token);
        }
        allToken[_token]=true;
    }

    //return All token list
    function getTokenlist() public view returns (address[]){
        return allTokenList;
    }

    function plusUserToken(address _user, address _token) public {
        if(!registeredToken[_user][_token]){
            token_list[_user].push(_token);
        }
        registeredToken[_user][_token]=true;
    }
    
    //return User's token list
    function getUserTokenlist(address _user) public view returns (address[]){
        return token_list[_user];
    }
    

}

contract Voting{
    mapping(address=>bool) public rewarded;
    function gettingReward(address _voter, uint256 _amount) public returns (bool) {}
}

