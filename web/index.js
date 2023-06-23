let currentTimer = 0;
var interval
let isDead = false

window.addEventListener('message', (event) => {
    if (event.data.type === 'show') {
        document.body.style.display = 'block';
        document.querySelector('.screen').style.display = 'block';

        isDead = true
        currentTimer = event.data.timer
        $('#header').text(event.data.header)
        $('#desc').text(event.data.desc)

        $('#time').text(new Date(currentTimer * 1000).toISOString().substr(14, 5))
        clearTimeout(interval)
        interval = setInterval(timer, 1000)
    } else if (event.data.type === 'hide') {
        document.body.style.display = 'none';
        document.querySelector('.screen').style.display = 'none';

        isDead  = false
        currentTimer = 0
    }
});

function timer(){
    if (isDead) {
        if (currentTimer < 0) {
            $.post(`https://${GetParentResourceName()}/time_expired`);
        } else {
            $('#time').text(new Date(currentTimer * 1000).toISOString().substr(14, 5));
            currentTimer = currentTimer - 1;
        }
    }

}