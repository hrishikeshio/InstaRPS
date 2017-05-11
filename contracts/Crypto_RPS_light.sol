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

import "./strings.sol";

pragma solidity ^0.4.4;
contract Crypto_RPS
{
  using strings for *; 

  address owner;
  address opponent;
  uint256 stake;
  bool matched = false;
  uint256 expirationBlockTime;
  uint256 nonce_1;
  uint256 nonce_2;
  string hand_1;
  string hand_2;
  uint256 player1balance_1;
  uint256 player1balance_2;
  uint256 player2balance_1;
  uint256 player2balance_2;
  address p1addr;
  address p2addr;
  uint8 winner;
  
  
  modifier onlyOwner() {
    if (msg.sender!=owner) throw;
    _;
  }

  modifier isMatched() {
    if(!matched) throw;
    _;
  }

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
  function Crypto_RPS(address _opponent)
  payable
  {
    if (msg.value<=0) throw;

    owner= msg.sender;
    opponent = _opponent;
    stake = msg.value;
    totalPublicDuels=1;
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

  function () {} //no fallback, use the functions to play

  function matchStake() 
  payable
  {
    if (msg.sender != opponent) throw;
    if (msg.value != stake) throw;
    if (matched) throw;
    matched = true;
  }
  event LogClose(uint256, string, uint256, uint256);

  function announceWinner(
   bytes32 p1h,
   uint8 p1v,
   bytes32 p1r,
   bytes32 p1s,
   bytes32 p2h,
   uint8 p2v,
   bytes32 p2r,
   bytes32 p2s,
   string p1m,
   string p2m) public constant returns (uint8 result, uint256 player1balance_1, uint256 player1balance_2)
  {
    p1addr= ecrecover(p1h, p1v, p1r, p1s);
    if (p1addr!=owner) throw;
    //  bool p1honest=true;
    p2addr= ecrecover(p2h, p2v, p2r, p2s);
    if (p2addr!=opponent) throw;
    //bool p2honest=true;
    //return(p1honest,p2honest);

    (nonce_1, hand_1, player1balance_1, player2balance_1) = decodeMessage(p1m);


    (nonce_2, hand_2, player1balance_2, player2balance_2) = decodeMessage(p2m);

    if (nonce_1!=nonce_2) throw;
    if (player2balance_1!=player2balance_2) throw;
    if (player1balance_1!=player1balance_2) throw;

    //Consensus reached 

    if (payoffMatrix[hand_1][hand_2]==0) //draw
    {
     result=9;
   }
   else if (payoffMatrix[hand_1][hand_2]==1) //1 win
   {
    result=1;
  }
  else if (payoffMatrix[hand_1][hand_2]==2) //2 wins
  {
    result=2;
  }
  return(result, player2balance_1, player1balance_2);


}

function decodeMessage(string message) public constant returns (uint256 _nonce, string _hand, uint256 _player1balance, uint256 _player2balance)
{
    var s = message.toSlice();
    var delim = "|".toSlice();

    _nonce = stringToUint(s.split(delim).toString());
    _hand = s.split(delim).toString();
    _player1balance = stringToUint(s.split(delim).toString());
    _player2balance = stringToUint(s.split(delim).toString());
}

function close(bytes32 p1h,
   uint8 p1v,
   bytes32 p1r,
   bytes32 p1s,
   bytes32 p2h,
   uint8 p2v,
   bytes32 p2r,
   bytes32 p2s,
   string p1m,
   string p2m)
{

  var (winner, p1b, p2b) = announceWinner(p1h, p1v, p1r, p1s, p2h, p2v, p2r, p2s, p1m, p2m);
  
  if(!opponent.send(p2b)) throw;
  if(!owner.send(this.balance)) throw;

}
// //  event Log(string text, bool called, uint value);
// //event duels(address p1,uint gambleValue);
// //  event newPublicGame(bytes32 gameHash, address player_1, uint gambleValue, uint gameIndex);
// //  event matchedPublicGame(bytes32 gameHash, address player_1, address player_2,  uint gambleValue, uint gameIndex);
// event solvedPublicGame(address player_1, string hand_1, address player_2, string hand_2, uint gambleValue, Results result, uint gameIndex);    
// function createPublicGame(bytes32 cryptedH)//, uint blockNumber)
// {
//   //hand already used
//   if (publicGameHashToIndex[cryptedH]!=0)
//   {
//     throw;
//   }
//   /* if (blockNumber<block.number-100 || blockNumber>block.number) */
//   /*   { */
//     /*  throw; */
//     /*   } */
//     uint gambleValue;
//     //    Log("waiting",true, msg.value/1 ether);
//     //    publicDuels.push(publicDuel(msg.sender,cryptedH,"",blockNumber,0,0x0,"",0,Results.commit,gambleValue,0));
//     publicDuels.push(publicDuel(msg.sender,cryptedH,"",block.number,0,0x0,"",0,Results.commit,gambleValue,0));
//     //    duels(publicDuels[0].player_1,publicDuels[0].gambleValue);
//     //    duels(publicDuels[1].player_1,publicDuels[1].gambleValue);
//     //    duels(publicDuels[totalPublicDuels].player_1,publicDuels[totalPublicDuels].gambleValue);
//     publicGameHashToIndex[cryptedH]=totalPublicDuels;
//     //    newPublicGame(cryptedH, msg.sender, gambleValue, totalPublicDuels);
//     totalPublicDuels++;
//   }

//   function answerPublicRock(bytes32 gameHash)

//   {
//     //    Log("answered rock",true, msg.value/1 ether);
//     answerPublic(gameHash, "rock");
//   }

//   function answerPublicPaper(bytes32 gameHash)
//   {
//     //    Log("answered paper",true, msg.value/1 ether);
//     answerPublic(gameHash, "paper");
//   }

//   function answerPublicScissors(bytes32 gameHash)
//   {
//     //    Log("answered scissors",true, msg.value/1 ether);
//     answerPublic(gameHash, "scissors");
//   }

//   function answerPublic(bytes32 gameHash, string hand) private
//   {
//     uint gameIndex=publicGameHashToIndex[gameHash];
//     if (publicDuels[gameIndex].result!=Results.commit)
//     {
//       throw;
//     }

//     //    Log("answered",true, msg.value/1 ether);
//     publicDuels[gameIndex].player_2=msg.sender;
//     publicDuels[gameIndex].hand_2=hand;
//     publicDuels[gameIndex].blockNumber_2=block.number;
//     publicDuels[gameIndex].result=Results.matched;
//     //    matchedPublicGame(gameHash, publicDuels[gameIndex].player_1, msg.sender,  publicDuels[gameIndex].gambleValue, gameIndex);

//   }


//   function revealRock(bytes32 gameHash, string secret)
//   {
//     reveal(gameHash, secret, "rock");
//   }
//   function revealPaper(bytes32 gameHash, string secret)
//   {
//     reveal(gameHash, secret, "paper");
//   }
//   function revealScissors(bytes32 gameHash, string secret)
//   {
//     reveal(gameHash, secret, "scissors");
//   }

//   event cryptedHStored(bytes32 ch);
//   function reveal(bytes32 gameHash, string secret, string hand) private
//   {
//     //    Log("reveal",true, msg.value/1 ether);
//     uint gameIndex=publicGameHashToIndex[gameHash];
    
//     cryptedHStored(publicDuels[gameIndex].cryptedHand_1);
//     cryptedHStored(sha3(secret, hand));
//     if (publicDuels[gameIndex].result==Results.matched &&
//       publicDuels[gameIndex].player_1==msg.sender &&
//       publicDuels[gameIndex].cryptedHand_1==sha3(secret, hand))//,publicDuels[gameIndex].blockNumber_1))
//     {
//       //  Log("ok revealed",true, msg.value/1 ether);
//       publicDuels[gameIndex].hand_1=hand;
//       solvePublicDuel(gameIndex);
//     }
//     else
//     {
//       //  Log("failed",true, msg.value/1 ether);
//       throw;
//       }//player has nothing to reveal
//     }
    
//     //payout
//     function solvePublicDuel(uint gameIndex) private
//     {
//       uint gambleValue=publicDuels[gameIndex].gambleValue;

//       if (payoffMatrix[publicDuels[gameIndex].hand_1][publicDuels[gameIndex].hand_2]==0) //draw
//       {
//         publicDuels[gameIndex].result=Results.draw;
//       }
//       else if (payoffMatrix[publicDuels[gameIndex].hand_1][publicDuels[gameIndex].hand_2]==1) //1 win
//       {
//         publicDuels[gameIndex].result=Results.win1;
//       }
//       else if (payoffMatrix[publicDuels[gameIndex].hand_1][publicDuels[gameIndex].hand_2]==2) //2 wins
//       {
//         publicDuels[gameIndex].result=Results.win2;
//       }
//       solvedPublicGame(msg.sender,  publicDuels[gameIndex].hand_1, publicDuels[gameIndex].player_2, publicDuels[gameIndex].hand_2, publicDuels[gameIndex].gambleValue, publicDuels[gameIndex].result, gameIndex);
//     }




    
//     function getTotalPublicDuels() constant returns(uint _totalPublicDuels)
//     {
//       return totalPublicDuels;
//     }

//     function fromPublicGameHashToIndex(bytes32 gameHash) constant returns(uint gameIndex)
//     {
//       return publicGameHashToIndex[gameHash];
//     }

//     function getPublicDuels(uint gameIndex) constant returns(address p1, bytes32 cryptedHand1, string hand1, uint256 blockNumber_1, uint256 blockNumber_1_reveal, address p2, string hand2, uint256 blockNumber_2, Results result, uint256 gambleValue, uint8 payoutStatus)
//     {
//       p1 = publicDuels[gameIndex].player_1;
//       cryptedHand1 = publicDuels[gameIndex].cryptedHand_1;
//       hand1 = publicDuels[gameIndex].hand_1;
//       blockNumber_1=publicDuels[gameIndex].blockNumber_1;
//       blockNumber_1_reveal=publicDuels[gameIndex].blockNumber_1_reveal;
//       p2 = publicDuels[gameIndex].player_2;
//       hand2 = publicDuels[gameIndex].hand_2;
//       blockNumber_2=publicDuels[gameIndex].blockNumber_2;
//       result=publicDuels[gameIndex].result;
//       gambleValue=publicDuels[gameIndex].gambleValue;
//       payoutStatus=publicDuels[gameIndex].payoutStatus;    
//     }
//     function getNonce(bytes message) internal returns (uint64 nonce) {
//       // don't care about length of message since nonce is always at a fixed position
//       assembly {
//         nonce := mload(add(message, 12))
//       }
//     }

    function getBlanace() public constant returns (uint256)
    {
     return this.balance;
   }
   function signatureSplit(bytes signature) private returns (bytes32 r, bytes32 s, uint8 v) {
    // The signature format is a compact form of:
    //   {bytes32 r}{bytes32 s}{uint8 v}
    // Compact means, uint8 is not padded to 32 bytes.
    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      // Here we are loading the last 32 bytes, including 31 bytes
      // of 's'. There is no 'mload8' to do this.
      //
      // 'byte' is not working due to the Solidity parser, so lets
      // use the second best option, 'and'
      v := and(mload(add(signature, 65)), 1)
    }
    // old geth sends a `v` value of [0,1], while the new, in line with the YP sends [27,28]
    if(v < 27) v += 27;
  }


  function getTransferRawAddress(bytes memory signed_transfer) internal returns (bytes memory, address) {
    uint signature_start;
    uint length;
    bytes memory signature;
    bytes memory transfer_raw;
    bytes32 transfer_hash;
    address transfer_address;

    length = signed_transfer.length;
    signature_start = length - 65;
    signature = slice(signed_transfer, signature_start, length);
    transfer_raw = slice(signed_transfer, 0, signature_start);

    transfer_hash = sha3(transfer_raw);
    var (r, s, v) = signatureSplit(signature);
    transfer_address = ecrecover(transfer_hash, v, r, s);

    return (transfer_raw, transfer_address);
  }

  function slice(bytes a, uint start, uint end) private returns (bytes n) {
    if (a.length < end) {
      throw;
    }
    if (start < 0) {
      throw;
    }

    n = new bytes(end - start);
    for (uint i = start; i < end; i++) { //python style slice
      n[i - start] = a[i];
    }
  }
  function stringToUint(string s) constant returns (uint result) {
    bytes memory b = bytes(s);
    uint i;
    result = 0;
    for (i = 0; i < b.length; i++) {
      uint c = uint(b[i]);
      if (c >= 48 && c <= 57) {
        result = result * 10 + (c - 48);
      }
    }
  }
  function verify( bytes32 hash, uint8 v, bytes32 r, bytes32 s) constant returns(address retAddr) {
    retAddr= ecrecover(hash, v, r, s);
  }


}


