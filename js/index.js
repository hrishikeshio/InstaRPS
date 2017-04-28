$(document).ready(function () {
  if (typeof web3 !== 'undefined') {
  // Use Mist/MetaMask's provider
    window.web3 = new Web3(web3.currentProvider)
  } else {
    console.log('No web3? You should consider trying MetaMask!')
  // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    window.web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'))
  }
  $('#btn_stake').click(function () {
    let stake = $('#stake_val').val()
    let contract = $('#contractAddress').val()
    console.log(stake)
    console.log(contract)
    web3.eth.sendTransaction({'from': web3.eth.defaultAccount, 'to': contract, 'value': stake })
  })
  $('#btn_play').click(function () {
    console.log('play clicked')
    let hand = $('#play_hand').val()
    let secret = $('#play_secret').val()
    let nonce = $('#play_nonce').val()
    let p1b = $('#play_p1b').val()
    let p2b = $('#play_p2b').val()

    let encryptedHand = web3.sha3(hand + secret)
    let msg = nonce.toString() + '|' + hand + '|' + p1b.toString() + '|' + p2b.toString()
    console.log(msg)
    let signed = web3.eth.sign(web3.eth.defaultAccount, msg, function (err, res) {
      if (!err) {
        console.log(res)
        $('#play_result').html(res)
      }
    })
  })
})
