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
  let autodownload = db.collection('autodownload')

  console.log('Creating indexes...')
  torrents.createIndex({ 'meta.name': 1 })
  torrents.createIndex({ 'meta.episode': 1 })
  torrents.createIndex({ 'meta.group': 1 })

  autodownload.createIndex({ 'name': 1 })
  autodownload.createIndex({ 'group': 1 })

  const app = express()

  app.use(bodyParser.json())
  app.use(express.static('public'))

  app.get('/api/anime', (req, res) => {
    torrents.find().sort({ pubDate: -1 }).limit(1000).toArray().then(t => res.send(t))
  })

  app.get('/api/autodownload', (req, res) => {
    autodownload.find().toArray().then(a => res.send(a))
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
        }, { $set: e }, {
            upsert: true
          }).then(entry => {
            if (entry.meta) {
              autodownload.find({
                name: entry.meta.name,
                group: entry.meta.group
              }).then(res => {
                if (res) {
                  download(entry.link)
                }
              })
            }
          })
      })
    })
  }

  fetchRSS()

  setInterval(() => fetchRSS(), 60000 * 10)

  function toggle (name, group) {
    console.log('toggling', name, group)
    return autodownload.findOne({
      name,
      group
    }).then(result => {
      if (result) {
        return autodownload.deleteOne({
          name, group
        })
      } else {
        downloadAll(name, group)
        return autodownload.insertOne({
          name, group
        })
      }
    })
  }

  function downloadAll (name, group) {
    console.log('downloading all', name, group)
    return torrents.find({
      'meta.name': name,
      'meta.group': group,
      'downloaded': { $exists: false }
    }).toArray().then(res => {
      console.log('Would download', res)
      res.forEach(entry => download(entry.link).then(() => console.log('downloaded')).catch(err => console.log(err)))
    })
  }

  app.post('/api/toggle', (req, res) => {
    toggle(req.body.name, req.body.group)
      .then(() => res.send({ status: 'ok' }))
      .catch(err => {
        console.log(err)
        res.send(500, err)
      })
  })

  function download (t) {

    console.log('downloading', t)

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
          path: t,
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

    return request(login)
      .then(() => request(download))
      .then(() => torrents.updateOne({ link: t }, {
        $set: { downloaded: true }
      }))
  }

  app.post('/api/download', (req, res) => {
    download(req.body.link)
      .then(resp => res.send('ok'))
      .catch(err => res.err(err))
  })

  const server = app.listen(process.env.PORT || 3000, () => console.log('Getter app listening on port ' + server.address().port))
})


