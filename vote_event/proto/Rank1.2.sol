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

contract Rank{
    using SafeMath for uint256;    
    
    address owner;
    
    mapping(uint256 => address) public ranking; // ranking_idx => ranker
    mapping(address => uint256) public ranker; // ranker => ranking_idx
    mapping(uint256 => uint256) accum_count; //amount of upper rankers
    mapping(uint256 => uint256) count;
    
    mapping(address => uint256) public score; // score of User

    
    
    //mapping(address => bool) isNew;
    
    constructor() public {
        owner=msg.sender;
    }

    
    function plusScore(address _user) public returns (bool) {
        uint256 nextScore;
        uint256 originScore;
        
        originScore=score[_user];
        
        if(count[originScore]!=0){
            count[originScore]=count[originScore].sub(1);
        }
        nextScore=originScore.add(1);
        score[_user]=nextScore; // plus one to score
        accum_count[originScore]=accum_count[originScore].add(1);
        
        //change ranking_idx if there are people at the same rank group
        if(count[originScore]!=0){
            //exchange ranking
            changeIndex(accum_count[originScore].add(1), ranker[_user]);
        }
        
        count[nextScore]=count[nextScore].add(1);
        return true;
    }
    
    function changeIndex(uint256 idx_A, uint256 idx_B) internal {
        address temp = ranking[idx_A]; // ranker addr
        ranking[idx_A] = ranking[idx_B];
        ranking[idx_B] = temp;

        ranker[ranking[idx_A]] = idx_A;
        ranker[ranking[idx_B]] = idx_B;
    }
    
    //function minusScore
    
}




