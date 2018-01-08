const express = require('express')
const RSSParser = require('rss-parser')
const bodyParser = require('body-parser')
const request = require('request-promise')
const app = express()

app.use(bodyParser.json())
app.use(express.static('public'))

app.get('/api/anime', (req, res) => {
    new Promise((resolve, reject) => {
        RSSParser.parseURL('https://nyaa.si/?page=rss&q=720&c=1_2&m=1&f=0', (err, res) => {
            if (err) {
                reject(err)
            } else {
                resolve(res.feed.entries)
            }
        })
    }).then(feed => {
        console.log(feed)
        res.json(feed)
    })
})

app.all('/api/download', (req, res) => {
    let cookieJar = request.jar()
    let login = {
        method: 'POST',
        uri: 'http://192.168.0.199:8112/json',
        json: true,
        body: {
            id: 1,
            method: 'auth.login',
            params: ['']
        },
        jar: cookieJar,
        gzip: true
    }

    let download = {
        method: 'POST',
        uri: 'http://192.168.0.199:8112/json',
        json: true,
        body: {
            id: 2,
            method: 'web.add_torrents',
            params: [[{
                path: req.body.link,
                options: {
                    compact_allocation: false,
                    download_location: '/downloads',
                    move_completed: false,
                    move_completed_path: '/downloads',
                    max_connections: -1,
                    max_download_speed: -1,
                    max_upload_slots: -1,
                    max_upload_speed: -1,
                    prioritize_first_last_pieces: false
                }
            }]]
        },
        jar: cookieJar,
        gzip: true
    }

    request(login)
        .then(() => request(download))
        .then(resp => {
            console.log(resp)
            res.send('ok')
        })
        .catch(err => {
            console.log(err)
            res.send(500, err)
        })

})

const server = app.listen(process.env.PORT || 3000, () => console.log('Getter app listening on port ' + server.address().port))