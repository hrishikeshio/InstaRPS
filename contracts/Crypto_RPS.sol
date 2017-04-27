//                       , ; ,   .-'"""'-.   , ; ,
//                       \\|/  .'          '.  \|//
//                        \-;-/   ()   ()   \-;-/
//                        // ;               ; \\
//                       //__; :.         .; ;__\\
//                      `-----\'.'-.....-'.'/-----'
//                             '.'.-.-,_.'.'
//                               '(  (..-'
//                                 '-'
//   WHYSOS3RIOUS   PRESENTS :                          
//                                                                
//   ROCK PAPER SCISSORS
//   Challenge an opponent with an encrypted hand
//
//
// *** coded by WhySoS3rious, 2016.                                       ***//
// *** do not copy without authorization                          ***//
// *** contact : reddit    /u/WhySoS3rious                               ***//


// exemple results with secret = "testing"
//hand = "rock" :  web3.sha3("testing"+"rock")
// 0x8935dc293ca2ee08e33bad4f4061699a8f59ec637081944145ca19cbc8b39473
//hand = "paper" : 
// 0x859743aa01286a6a1eba5dbbcc4cf8eeaf1cc953a3118799ba290afff7125501
//hand = "scissors" : 
//0x35ccbb689808295e5c51510ed28a96a729e963a12d09c4a7a4ba000c9777e897




pragma solidity ^0.4.0;
contract Crypto_RPS
{

  address owner;
  uint256 maxGamble;
  uint256 expirationBlockTime;
  uint256 houseFee;
  uint256 houseTotal;

  
  modifier onlyOwner() {
    if (msg.sender!=owner) throw;
    _;
  }

  //for publicGames gameHash = cryptedHand_1
  enum Results{empty, commit, cancel, matched, win1, win2, draw, expired}
  struct publicDuel
  {
    address player_1;
    bytes32 cryptedHand_1;
    string hand_1;
    uint256 blockNumber_1;
    uint256 blockNumber_1_reveal;
    address player_2;
    string hand_2;
    uint256 blockNumber_2;
    Results result;
    uint256 gambleValue;
    uint8 payoutStatus; //0 ok, 1 throw, 2 throw, 3 both throw
  }
  publicDuel[] publicDuels;

  uint256 totalPublicDuels;
  mapping (bytes32 => uint) publicGameHashToIndex;

  mapping (string => mapping(string => int)) payoffMatrix;
  //constructor
  function Crypto_RPS()
  {
    owner= msg.sender;
  }

  function init_Crypto_RPS()
    onlyOwner
  {
    totalPublicDuels=1;
    maxGamble = 1 ether;
    houseFee = 5;  //in 1/1000th
    expirationBlockTime = 7200 ;//24 hour in blocks, time player 1 has to reveal once matched
    payoffMatrix["rock"]["rock"] = 0;
    payoffMatrix["rock"]["paper"] = 2;
    payoffMatrix["rock"]["scissors"] = 1;
    payoffMatrix["paper"]["rock"] = 1;
    payoffMatrix["paper"]["paper"] = 0;
    payoffMatrix["paper"]["scissors"] = 2;
    payoffMatrix["scissors"]["rock"] = 2;
    payoffMatrix["scissors"]["paper"] = 1;
    payoffMatrix["scissors"]["scissors"] = 0;
    publicDuels.push(publicDuel(0x0,0x0,"",0x0,0,0x0,"",0,Results.cancel,0,0));
  }

  function () {throw;} //no fallback, use the functions to play

  function changeSettings(uint _expirationBlockTime_, uint _maxGamble_, uint _houseFee_)
    onlyOwner
  {
    expirationBlockTime=_expirationBlockTime_;
    maxGamble=_maxGamble_;
    houseFee=_houseFee_;
  }

  function changeOwner()
    onlyOwner
  {
    owner=msg.sender;
  }

  function cancelPublicGame(bytes32 gameHash)
  {
    uint gameIndex = publicGameHashToIndex[gameHash];
    if (msg.sender==publicDuels[gameIndex].player_1 && publicDuels[gameIndex].result==Results.commit)
      {
	if (!msg.sender.send(publicDuels[gameIndex].gambleValue))
	  {
	    throw;
	  }
	publicDuels[gameIndex].result=Results.cancel;
      }
    else { throw;}
  }	


  //  event Log(string text, bool called, uint value);
  //event duels(address p1,uint gambleValue);
  //  event newPublicGame(bytes32 gameHash, address player_1, uint gambleValue, uint gameIndex);
  //  event matchedPublicGame(bytes32 gameHash, address player_1, address player_2,  uint gambleValue, uint gameIndex);
  event solvedPublicGame(address player_1, string hand_1, address player_2, string hand_2, uint gambleValue, Results result, uint gameIndex);    
  function createPublicGame(bytes32 cryptedH)//, uint blockNumber)
    payable
  {
    //hand already used
    if (publicGameHashToIndex[cryptedH]!=0)
      {
	throw;
      }
    /* if (blockNumber<block.number-100 || blockNumber>block.number) */
    /*   { */
    /* 	throw; */
    /*   } */
    uint gambleValue;
    if (msg.value > maxGamble) 
      {
	//Log("too high",true, msg.value/1 ether);
	gambleValue=maxGamble;
	if (!msg.sender.send(msg.value-maxGamble))
	  {
	    //Log("refund failed",true, (msg.value-maxGamble)/1 ether);
	    throw;
	  }
      }
    else
      {
	gambleValue=msg.value;
      }
    //    Log("waiting",true, msg.value/1 ether);
    //    publicDuels.push(publicDuel(msg.sender,cryptedH,"",blockNumber,0,0x0,"",0,Results.commit,gambleValue,0));
    publicDuels.push(publicDuel(msg.sender,cryptedH,"",block.number,0,0x0,"",0,Results.commit,gambleValue,0));
    //    duels(publicDuels[0].player_1,publicDuels[0].gambleValue);
    //    duels(publicDuels[1].player_1,publicDuels[1].gambleValue);
    //    duels(publicDuels[totalPublicDuels].player_1,publicDuels[totalPublicDuels].gambleValue);
    publicGameHashToIndex[cryptedH]=totalPublicDuels;
    //    newPublicGame(cryptedH, msg.sender, gambleValue, totalPublicDuels);
    totalPublicDuels++;
  }

  function answerPublicRock(bytes32 gameHash)
    payable
  {
    //    Log("answered rock",true, msg.value/1 ether);
    answerPublic(gameHash, "rock");
  }

  function answerPublicPaper(bytes32 gameHash)
    payable
  {
    //    Log("answered paper",true, msg.value/1 ether);
    answerPublic(gameHash, "paper");
  }

  function answerPublicScissors(bytes32 gameHash)
    payable
  {
    //    Log("answered scissors",true, msg.value/1 ether);
    answerPublic(gameHash, "scissors");
  }

  function answerPublic(bytes32 gameHash, string hand) private
  {
    uint gameIndex=publicGameHashToIndex[gameHash];
    if (publicDuels[gameIndex].result!=Results.commit)
      {
	throw;
      }
    uint gambleValue;
    if (msg.value > publicDuels[gameIndex].gambleValue) 
      {
	//	Log("too high",true, msg.value/1 ether);
	//	Log("refund",true, (msg.value-maxGamble)/1 ether);
	if (!msg.sender.send(msg.value-publicDuels[gameIndex].gambleValue))
	  {
	    throw;
	  }
      }
    else if (msg.value < publicDuels[gameIndex].gambleValue)
      {
	throw;
      }
    //    Log("answered",true, msg.value/1 ether);
    publicDuels[gameIndex].player_2=msg.sender;
    publicDuels[gameIndex].hand_2=hand;
    publicDuels[gameIndex].blockNumber_2=block.number;
    publicDuels[gameIndex].result=Results.matched;
    //    matchedPublicGame(gameHash, publicDuels[gameIndex].player_1, msg.sender,  publicDuels[gameIndex].gambleValue, gameIndex);

  }
 

  function revealRock(bytes32 gameHash, string secret)
  {
    reveal(gameHash, secret, "rock");
  }
  function revealPaper(bytes32 gameHash, string secret)
  {
    reveal(gameHash, secret, "paper");
  }
  function revealScissors(bytes32 gameHash, string secret)
  {
    reveal(gameHash, secret, "scissors");
  }

  event cryptedHStored(bytes32 ch);
  function reveal(bytes32 gameHash, string secret, string hand) private
  {
    //    Log("reveal",true, msg.value/1 ether);
    uint gameIndex=publicGameHashToIndex[gameHash];
    
    cryptedHStored(publicDuels[gameIndex].cryptedHand_1);
    cryptedHStored(sha3(secret, hand));
      if (publicDuels[gameIndex].result==Results.matched &&
	publicDuels[gameIndex].player_1==msg.sender &&
	publicDuels[gameIndex].cryptedHand_1==sha3(secret, hand))//,publicDuels[gameIndex].blockNumber_1))
      {
	//	Log("ok revealed",true, msg.value/1 ether);
	publicDuels[gameIndex].hand_1=hand;
	solvePublicDuel(gameIndex);
      }
    else
      {
	//	Log("failed",true, msg.value/1 ether);
	throw;
      }//player has nothing to reveal
  }
    
  //payout
  function solvePublicDuel(uint gameIndex) private
  {
    uint gambleValue=publicDuels[gameIndex].gambleValue;
    uint housePayout=gambleValue*houseFee/1000;
    uint payout1;
    uint payout2;
    
    if (payoffMatrix[publicDuels[gameIndex].hand_1][publicDuels[gameIndex].hand_2]==0) //draw
      {
	publicDuels[gameIndex].result=Results.draw;
	houseTotal+=2*housePayout;
	payout1=gambleValue-housePayout;
	payout2=payout1;
      }
    else if (payoffMatrix[publicDuels[gameIndex].hand_1][publicDuels[gameIndex].hand_2]==1) //1 win
      {
	publicDuels[gameIndex].result=Results.win1;
	houseTotal+=2*housePayout-1;
	payout1=2*(gambleValue-housePayout);
	payout2=1;
      }
    else if (payoffMatrix[publicDuels[gameIndex].hand_1][publicDuels[gameIndex].hand_2]==2) //2 wins
      {
	publicDuels[gameIndex].result=Results.win2;
	houseTotal+=2*housePayout-1;
	payout1=1;
	payout2=2*(gambleValue-housePayout);
      }
   solvedPublicGame(msg.sender,  publicDuels[gameIndex].hand_1, publicDuels[gameIndex].player_2, publicDuels[gameIndex].hand_2, publicDuels[gameIndex].gambleValue, publicDuels[gameIndex].result, gameIndex);
   payout(gameIndex, payout1,payout2);
  }

  function payout(uint gameIndex, uint payout1, uint payout2) private
  {
    //payouts
    if (!publicDuels[gameIndex].player_1.send(payout1))
      {
	publicDuels[gameIndex].payoutStatus=1;
      }
    if (!publicDuels[gameIndex].player_2.send(payout2))
      {
	if (publicDuels[gameIndex].payoutStatus==1)
	  {
	    publicDuels[gameIndex].payoutStatus=3;
	  }
	else
	  {
	    publicDuels[gameIndex].payoutStatus=2;
	  }
      }
  }


  //callable by player 2 after expiration Time
  function claimExpiredDuel(bytes32 gameHash)
  {
    var gameIndex=publicGameHashToIndex[gameHash];
    if (msg.sender==publicDuels[gameIndex].player_2 &&
	publicDuels[gameIndex].blockNumber_2+expirationBlockTime<block.number &&
	publicDuels[gameIndex].result==Results.matched)
      {
	publicDuels[gameIndex].result=Results.expired;
	uint housePayout=publicDuels[gameIndex].gambleValue*houseFee/1000;
	houseTotal+=2*housePayout-1;
	uint payout1=1;
	uint payout2=2*(publicDuels[gameIndex].gambleValue-housePayout);
	solvedPublicGame(msg.sender,  publicDuels[gameIndex].hand_1, publicDuels[gameIndex].player_2, publicDuels[gameIndex].hand_2, publicDuels[gameIndex].gambleValue, publicDuels[gameIndex].result, gameIndex);
	payout(gameIndex, payout1,payout2);
      }
  }


  function solveStalledPublicDuel(uint gameIndex, uint houseRecoverValue)
    onlyOwner
  {
    if (publicDuels[gameIndex].payoutStatus==1 || publicDuels[gameIndex].payoutStatus ==2 || publicDuels[gameIndex].payoutStatus ==3)
      {
	if (houseRecoverValue<=publicDuels[gameIndex].gambleValue)
	  {
	    publicDuels[gameIndex].payoutStatus=0;
	    houseTotal+=houseRecoverValue;
	  }
      }
  }

    
  function payHouse() 
    onlyOwner
  {
    if (!owner.send(houseTotal))
      {
	throw;
      }
    houseTotal=0;
  }

  function getTotalPublicDuels() constant returns(uint _totalPublicDuels)
  {
    return totalPublicDuels;
  }

  function fromPublicGameHashToIndex(bytes32 gameHash) constant returns(uint gameIndex)
  {
    return publicGameHashToIndex[gameHash];
  }

  function getPublicDuels(uint gameIndex) constant returns(address p1, bytes32 cryptedHand1, string hand1, uint256 blockNumber_1, uint256 blockNumber_1_reveal, address p2, string hand2, uint256 blockNumber_2, Results result, uint256 gambleValue, uint8 payoutStatus)
  {
    p1 = publicDuels[gameIndex].player_1;
    cryptedHand1 = publicDuels[gameIndex].cryptedHand_1;
    hand1 = publicDuels[gameIndex].hand_1;
    blockNumber_1=publicDuels[gameIndex].blockNumber_1;
    blockNumber_1_reveal=publicDuels[gameIndex].blockNumber_1_reveal;
    p2 = publicDuels[gameIndex].player_2;
    hand2 = publicDuels[gameIndex].hand_2;
    blockNumber_2=publicDuels[gameIndex].blockNumber_2;
    result=publicDuels[gameIndex].result;
    gambleValue=publicDuels[gameIndex].gambleValue;
    payoutStatus=publicDuels[gameIndex].payoutStatus;    
  }

      //**********************************************
    //                 Nicknames FUNCTIONS                    //
    //**********************************************

    //User set nickname
    mapping (address => string) nicknames;
    function setNickname(string name) 
    {
        if (bytes(name).length >= 2 && bytes(name).length <= 30)
            nicknames[msg.sender] = name;
    }
    function getNickname(address _address) constant returns(string _name) {
        _name = nicknames[_address];
    }


}

