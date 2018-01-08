const express = require('express')
const RSSParser = require('rss-parser')
const bodyParser = require('body-parser')
const request = require('request-promise')
const MongoClient = require('mongodb').MongoClient
const url = 'mongodb://mongodb/getter-robo'
const regex = /^\[(.+?)\]\s+([^\[\]]+?)\s*-\s+(\d+)\s+.*(720|1080|480).*\.(mp4|mkv)$/

MongoClient.connect(url).then(client => {
  let db = client.db('getter-robo')
  let torrents = db.collection('torrents')
  torrents.createIndexes([
    { "meta.name": 1 },
    { "meta.group": 1 },
    { "meta.episode": 1 },
    { "pubDate": 1 }
  ])
  const app = express()

  app.use(bodyParser.json())
  app.use(express.static('public'))

  app.get('/api/anime', (req, res) => {
    torrents.find().sort({ pubDate: -1 }).limit(1000).toArray().then(t => res.send(t))
  })
  function fetchRSS () {
    new Promise((resolve, reject) => {
      RSSParser.parseURL('https://nyaa.si/?page=rss&q=720&c=1_2&m=1&f=0', (err, res) => {
        if (err) {
          reject(err)
        } else {
          resolve(res.feed.entries)
        }
      })
    }).then(entries => {
      entries.forEach(e => {
        let matches = regex.exec(e.title)
        e.pubDate = new Date(e.pubDate)
        e.isoDate = new Date(e.isoDate)
        if (matches) {
          e.meta = {
            group: matches[1],
            name: matches[2],
            episode: matches[3],
            resolution: parseInt(matches[4]),
            extention: matches[5]  
          }
        }
      })
      return entries
    }).then(entries => {
      entries.forEach(e => {
        torrents.update({
          guid: e.guid
        }, e, {
            upsert: true
          })
      })
    })
  }

  fetchRSS()

  setInterval(() => fetchRSS(), 60000 * 10)

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
})


