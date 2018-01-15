const express = require('express')
const RSSParser = require('rss-parser')
const bodyParser = require('body-parser')
const request = require('request-promise')
const MongoClient = require('mongodb').MongoClient
const Promise = require('bluebird')
const url = 'mongodb://mongodb/getter-robo'
const regex = /^\[(.+?)\]\s+([^\[\]]+?)\s*-\s+(\d+)\s+.*(720|1080|480).*\.(mp4|mkv)$/
const google = require('googleapis')
const customsearch = google.customsearch('v1')
const { WebClient } = require('@slack/client')

// You can get a custom search engine id at
// https://www.google.com/cse/create/new
const CX = process.env.GOOGLE_CSE_CX;
const API_KEY = process.env.GOOGLE_API_KEY;

// An access token (from your Slack app or custom integration - xoxp, xoxb, or xoxa)
const token = process.env.SLACK_TOKEN;

const web = new WebClient(token);

let imageSearch = q => {
  if (CX && API_KEY) {
    return new Promise((resolve, reject) => {
      customsearch.cse.list({ cx: CX, q: q, auth: API_KEY, searchType: 'image', imgSize: 'large' }, (err, res) => err ? reject(err) : resolve(res.items))
    })
  } else {
    console.log('No CX / API_KEY')
    return Promise.resolve()
  }
}

let notify = (channelId, msg, opts) => {
  if (channelId, msg, opts) {

    return web.chat.postMessage(channelId, msg, opts)
      .then((res) => {
        // `res` contains information about the posted message
        console.log('Message sent: ', res.ts);
      })
  } else {
    console.log('No SLACK STUFF')
    return Promise.resolve()
  }

}

let parseRSSUrl = url => {
  return new Promise((resolve, reject) => {
    RSSParser.parseURL(url, (err, res) => err ? reject(err) : resolve(res.feed.entries))
  })
}

let cookieJar = request.jar()
let reqId = 0;

let deluge = (method, params) => {
  return request({
    method: 'POST',
    uri: 'http://192.168.0.199:8112/json',
    json: true,
    body: {
      id: ++reqId,
      method: method,
      params: params
    },
    jar: cookieJar,
    gzip: true
  })
}

MongoClient.connect(url).then(client => {
  let db = client.db('getter-robo')
  let torrents = db.collection('torrents')
  let autodownload = db.collection('autodownload')
  let anime = db.collection('anime')

  console.log('Creating indexes...')
  torrents.createIndex({ 'meta.name': 1 })
  torrents.createIndex({ 'meta.episode': 1 })
  torrents.createIndex({ 'meta.group': 1 })

  autodownload.createIndex({ 'name': 1 })
  autodownload.createIndex({ 'group': 1 })

  anime.createIndex({ 'name': 1 })

  const app = express()

  app.use(bodyParser.json())
  app.use(express.static('public'))

  app.get('/api/torrents', (req, res) => {
    torrents.find().sort({ pubDate: -1 }).limit(1000).toArray().then(t => res.send(t))
  })

  app.get('/api/anime', (req, res) => {
    torrents.aggregate([
      {
        $match: {
          meta: {
            $exists: true
          }
        }
      },
      {
        $sort: {
          pubDate: -1
        }
      },
      {
        $lookup: {
          from: 'anime',
          localField: 'meta.name',
          foreignField: 'name',
          as: 'anime'
        }
      },
      {
        $group: {
          _id: {
            anime: '$anime'
          },
          torrents: {
            $push: '$$ROOT'
          }
        }
      },
      {
        $project: {
          anime: {
            $arrayElemAt: ['$_id.anime', 0]
          },
          _id: 0,
          torrents: 1
        }
      }
    ]).toArray()
      .then(result => res.send(result))
      .catch(err => res.status(500).send(err))
  })

  app.get('/api/torrents/uncatalogued', (req, res) => {
    torrents.find({
      $exists: {
        meta: false
      }
    }).toArray()
      .then(results => res.send(results))
      .catch(err => res.status(500).send(err))
  })

  app.get('/api/autodownload', (req, res) => {
    autodownload.find().sort({
      pubDate: -1
    }).toArray().then(a => res.send(a))
  })

  function fetchRSS (query) {
    if (query) {
      query += ' 720'
    } else {
      query = '720'
    }

    query = encodeURI(query)

    return parseRSSUrl('https://nyaa.si/?page=rss&q=' + query + '&c=1_2&m=1&f=0')
      .map(e => {
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
        return e
      })
      .map(e => torrents.findOneAndUpdate({ guid: e.guid }, { $set: e }, { upsert: true }))
      .map(e => saveAnime(e))
      .map(e => fetchImage(e.value))
      .map(e => checkDownload(e))
      .then(entries => console.log('Parsed rss entries:', entries.length))
      .catch(err => console.error('Error fetching RSS', err))
  }

  function checkDownload (torrent) {
    if (torrent && !torrent.downloaded && torrent.meta) {
      return autodownload.findOne({
        name: torrent.meta.name,
        group: torrent.meta.group
      }).then(found => found ? download(torrent).then(() => torrent) : torrent)
    } else {
      return torrent
    }
  }

  function saveAnime (torrent) {
    // console.log('saveanime', torrent)
    if (torrent.meta) {
      return anime.findOneAndUpdate({ name: torrent.meta.name }, { $set: { name: torrent.meta.name } }, { upsert: true })
        .then(() => torrent)
    } else {
      return torrent
    }
  }

  function fetchImage (torrent) {
    if (torrent && torrent.meta) {
      return anime.findOne({ name: torrent.meta.name }).then(res => {
        if (!res || !res.link) {
          console.log('Getting image for', torrent.meta.name, res)
          return imageSearch(torrent.meta.name).then(imgs => {
            if (imgs) {
              console.log('Image data:', imgs[0])
              return anime.findOneAndUpdate({ name: torrent.meta.name }, {
                $set: imgs[0]
              }, { upsert: true }).then(() => torrent)
            }
          }).catch(err => {
            console.log('Error saving image data', err)
            return torrent
          }).thenReturn(torrent)
        } else {
          return torrent
        }
      })
    } else {
      return torrent
    }
  }

  fetchRSS()

  setInterval(() => fetchRSS(), 60000 * 10)

  function toggle (name, group) {
    return autodownload.findOne({ name, group }).then(result => {
      if (result) {
        console.log('Toggling off', name, group)
        return autodownload.deleteOne({ name, group })
      } else {
        console.log('Toggling on', name, group)
        return autodownload.insertOne({ name, group }).then(() => downloadAll(name, group))
      }
    })
  }

  function downloadAll (name, group) {
    console.log('downloading all', name, group)
    return Promise.resolve(torrents.find({
      'meta.name': name,
      'meta.group': group,
      'downloaded': { $exists: false }
    }).toArray()).map(torrent => download(torrent))
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
    return deluge('auth.login', [''])
      .then(() => deluge('web.add_torrents', [[{
        path: t.link,
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
      }]]))
      .then(() => torrents.updateOne({ link: t.link }, {
        $set: { downloaded: true }
      }))
      .then(() => {
        console.log('Downloaded', t)
        return t
      }).then(() => {
        return t.meta ? anime.findOne({ name: t.meta.name }) : undefined
      }).then(a => {
        console.log('notify anime', a)
        return notify('C4L2P062F', t.title + " downloaded!", {
          attachments: a ? [{ fallback: 'img', image_url: a.link }] : []
        })
      }).then(() => t).catch(err => {
        console.log(err)
        return t
      })
  }


  app.post('/api/download', (req, res) => {
    download(req.body)
      .then(resp => res.send('ok'))
      .catch(err => {
        console.log(err)
        res.status(500).send(err)
      })
  })

  const server = app.listen(process.env.PORT || 3000, () => console.log('Getter app listening on port ' + server.address().port))
})
