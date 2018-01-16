<template>
  <div class="container" v-if="anime">
    <div class="entry row" v-for="a in anime" :key="a.name">
      <div class="anime col-md-6 col-sm-12">
        <div v-if="a.link" class="img" :style="{backgroundImage: `url('${a.link}')`}"></div>
        <div>{{a.name}}</div>
      </div>
      <div class="col-md-6 col-sm-12">
        <div class="btn-group" v-for="(torrents, group) in a.torrents" :key="group">
          <button :class="{'btn-primary': isAutodownloading(a.name, group), 'btn-secondary': !isAutodownloading(a.name, group)}" class="btn btn-sm" @click="toggle(a.name, group)">{{group}}</button>
          <button @click="selectedTorrents = torrents" :class="{'btn-outline-primary': isAutodownloading(a.name, group), 'btn-outline-secondary': !isAutodownloading(a.name, group)}" class="btn btn-sm " v-b-modal.torrents>{{torrents[0].meta.episode}} ({{ago(torrents[0].pubDate)}})</button>
        </div>
      </div>
    </div>
    <!-- Modal Component -->
    <b-modal id="torrents" :title="selectedTorrents ? selectedTorrents[0].meta.group + ' ' +selectedTorrents[0].meta.name : ''">
      <div class="btn-group" v-for="torrent in selectedTorrents" :key="torrent.guid">
        <div @click="download(torrent)" :class="{'btn-primary': torrent.downloaded, 'btn-secondary': !torrent.downloaded}" class="btn">{{torrent.title}}</div>
      </div>
      <button class="btn btn-success" @click="fetch(selectedTorrents[0].meta.name)">Fetch this series</button>
    </b-modal>
  </div>
</template>

<script>
import _ from 'lodash'
import moment from 'moment'

var nest = function (seq, keys) {
  if (!keys.length) {
    return seq
  }
  var first = keys[0]
  var rest = keys.slice(1)
  return _.mapValues(_.groupBy(seq, first), function (value) {
    return nest(value, rest)
  })
}

export default {
  name: 'Main',
  data () {
    return {
      anime: undefined,
      autodownload: undefined,
      selectedTorrents: undefined
    }
  },
  mounted () {
    this.refresh()
  },
  methods: {
    download (torrent) {
      this.$http.post('/api/download', torrent).then(res => {
      })
    },
    toggle (name, group) {
      this.$http.post('/api/toggle', { name, group }).then(res => {
        this.refresh()
      })
    },
    last (arr) {
      return arr[arr.length - 1]
    },
    ago (date) {
      return moment(date).fromNow()
    },
    isAutodownloading (name, group) {
      return this.autodownload.find(d => d.name === name && d.group === group)
    },
    fetch (anime) {
      this.$http.get('/api/fetch?query=' + encodeURI(anime)).then(() => this.refresh())
    },
    refresh () {
      this.$http.get('/api/anime').then(res => {
        console.log(res.body)
        res.body.forEach(anime => {
          anime.torrents = nest(anime.torrents, [t => t.meta.group])
        })
        this.anime = res.body
      })

      this.$http.get('/api/autodownload').then(res => {
        this.autodownload = res.body
      })
    }
  }
}
</script>

<style scoped>
.anime {
  display: flex;
}

.anime > div {
  align-self: center;
}

.entry {
  margin: 1em 0;
}

.btn-group {
  margin: 0.2em 0.5em;
}

.img {
  height: 64px;
  width: 64px;
  background-repeat: no-repeat;
  background-size: cover;
  background-position: center center;
  margin: 0.2em;
}

.entry {
  border: 1px solid black;
}
</style>
