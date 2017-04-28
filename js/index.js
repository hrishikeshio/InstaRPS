startApp()
{
  $('btn_stake').click(function () {
    let stake = $('#stake_val').val()
    let contract = $('#contractAddress').val()
  })
  $('btn_play').click(function () {
    let hand = $('play_hand').val()
    let nonce = $('nonce').val()
    let p1b = $('play_p1b').val()
    let p2b = $('play_p2b').val()
  })
}
