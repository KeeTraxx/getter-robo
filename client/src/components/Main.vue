<template>
  <div class="container">
    <div class="entry row" v-for="a in anime" :key="a.name">
      <div class="anime col-md-6 col-sm-12">
        <div class="img" :style="{backgroundImage: `url('${a.link}')`}"></div>
        <div>{{a.name}}</div>
      </div>
      <div class="col-md-6 col-sm-12">
        <div class="btn-group" v-for="(torrents, group) in a.torrents" :key="group">
          <button :class="{'btn-primary': isAutodownloading(a.name, group), 'btn-secondary': !isAutodownloading(a.name, group)}" class="btn btn-sm" @click="toggle(a.name, group)">{{group}}</button>
          <button :class="{'btn-outline-primary': isAutodownloading(a.name, group), 'btn-outline-secondary': !isAutodownloading(a.name, group)}" class="btn btn-sm " @click="download(last(torrents))">{{last(torrents).meta.episode}} ({{ago(last(torrents).pubDate)}})</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import _ from 'lodash'
import moment from 'moment'

var nest = function (seq, keys) {
  if (!keys.length)
    return seq;
  var first = keys[0];
  var rest = keys.slice(1);
  return _.mapValues(_.groupBy(seq, first), function (value) {
    return nest(value, rest)
  });
};

export default {
  name: 'Main',
  data () {
    return {
      anime: [],
      autodownload: []
    }
  },
  mounted () {
    this.refresh()
  },
  methods: {
    download (torrent) {
      this.$http.post('/api/download', torrent).then(res => {
        console.log(res)
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
    urlMap (url) {
      return 
    },
    refresh () {
      this.$http.get('/api/anime').then(res => {
        res.body.forEach(anime => {
          //console.log(_.groupBy)
          anime.torrents = nest(anime.torrents, [t => t.meta.group])
        })
        this.anime = res.body
        console.log(this.anime)
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
}
</style>
