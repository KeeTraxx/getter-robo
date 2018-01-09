<template>
  <div class="container">
    <div class="entry row" v-for="kv in anime.filter(e => e.key != 'undefined')" :key="kv.key">
      <div class="col-md-6 col-sm-12">{{kv.key}}</div>
      <div class="col-md-6 col-sm-12">
        <div class="btn-group" v-for="group in kv.values" :key="group.key">
          <button :class="{'btn-primary': isAutodownloading(kv.key, group.key), 'btn-secondary': !isAutodownloading(kv.key, group.key)}" class="btn btn-sm" @click="toggle(kv.key, group.key)">{{group.key}}</button>
          <button :class="{'btn-outline-primary': isAutodownloading(kv.key, group.key), 'btn-outline-secondary': !isAutodownloading(kv.key, group.key)}" class="btn btn-sm " @click="download(last(group.values))">{{last(group.values).meta.episode}} ({{ago(last(group.values).pubDate)}})</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import * as d3 from 'd3'
import moment from 'moment'

const nester = d3
  .nest()
  .key(d => (d.meta ? d.meta.name : undefined))
  .key(d => (d.meta ? d.meta.group : undefined))
  .sortKeys(d3.ascending)

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
    refresh () {
      this.$http.get('/api/anime').then(res => {
        this.anime = nester.entries(res.body)
      })

      this.$http.get('/api/autodownload').then(res => {
        this.autodownload = res.body
      })
    }
  }
}
</script>

<style scoped>
.entry {
  margin: 1em 0;
}

.btn-group {
  margin: 0.2em 0.5em;
}
</style>
