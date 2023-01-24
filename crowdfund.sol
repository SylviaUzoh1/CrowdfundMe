// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20{
 function transfer(address, uint) external returns(bool);
 function transferFrom(address, address, uint) external returns(bool);

}

contract tech4dev{

  event Launch(
     uint id,
     address indexed creator,
    uint goal,
     uint32 startAt,
     uint32 endAt
  );
 
event Cancel(
    uint id
);
 
event Pledge(
   uint indexed id,
   address indexed caller,
   uint amount
);
    event Unpledge(uint indexed id, address indexed caller, uint amount);
    event Claim(uint id);
    event Refund(uint id, address indexed caller, uint amount);
 
struct Campaign {
    address creator;  
    uint goal;  
    uint pledged; 
    uint32 startAt; 
    uint32 endAt;  
    bool claimed;
    }
 
   IERC20 public immutable token;
 
uint public count;
 
mapping(uint => Campaign) public campaigns;
mapping(uint => mapping(address => uint)) public pledgedAmount;
 
constructor(address _token){
token = IERC20(_token);
}

function launch(uint _goal, uint32 _startAt, uint32 _endAt) external {
  require(_startAt >= block.timestamp, "startAt < now");
  require(_endAt >= _startAt, "endAt < startAt");
  require(_endAt <= block.timestamp + 90 days, "endAt > max duration");
  
  count +=1;
  
  campaigns[count] = Campaign(msg.sender, _goal, 0, _startAt, _endAt, false);
//campaign[1] = Campaign(msg.sender, 1000, 0, 2pm, 4pm, false);

  emit Launch(count, msg.sender, _goal, _startAt, _endAt);
}

//memory here is a temporary storage
function cancel(uint _id) external {
  Campaign memory campaign= campaigns[_id]; //the id of our campaign that we want to cancel inside our mapping
  require(campaign.creator == msg.sender, "You are not the creator");
  require(block.timestamp < campaign.startAt, "The campaign has started");
  
  delete campaigns[_id];
  emit Cancel(_id);
}

function pledge(uint _id, uint _amount) external {
  Campaign storage campaign= campaigns[_id];
  require(block.timestamp >= campaign.startAt, "The campaign has not started");
  require(block.timestamp <= campaign.endAt, "The campaign has ended");
  campaign.pledged +=_amount;
  pledgedAmount[_id][msg.sender] +=_amount;
  
  token.transferFrom(msg.sender, address(this), _amount);
  emit Pledge(_id, msg.sender, _amount);

}
function unpledge(uint _id, uint _amount) external {
  Campaign storage campaign= campaigns[_id]; //storage is used when we want to update our struct
  require(block.timestamp <= campaign.endAt, "The campaign has ended"); //you can also create a require statement just to be doubly sure the pledgee doesn't take more than pledged
  campaign.pledged -=_amount;
  pledgedAmount[_id][msg.sender] -=_amount;
  token.transfer(msg.sender, _amount);
  
  emit Unpledge(_id, msg.sender, _amount);  
}

function claim(uint _id) external {
  Campaign storage campaign= campaigns[_id];
  require(campaign.creator == msg.sender, "You are not the creator"); 
  require(block.timestamp > campaign.endAt, "The campaign has not ended"); 
  require(campaign.pledged >= campaign.goal, "Amount plegded is less than the goal");
  require(!campaign.claimed, "campaign has been claimed"); //require that campaign has not been claimed

  campaign.claimed = true;
  token.transfer(campaign.creator, campaign.pledged);
  emit Claim(_id);

}
//called by the pledgee
function refund(uint _id) external { //amount is not used because you'resending back everything
  Campaign memory campaign= campaigns[_id]; 
  require(block.timestamp > campaign.endAt, "The campaign has not ended");
  require(campaign.pledged < campaign.goal, "Amount plegded is greater than the goal"); 

  uint balance = pledgedAmount[_id][msg.sender];
  pledgedAmount[_id][msg.sender] = 0;
  token.transfer(msg.sender, balance);
  emit Refund(_id, msg.sender, balance);
}


}