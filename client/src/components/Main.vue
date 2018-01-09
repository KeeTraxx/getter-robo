<template>
  <div class="container">
      <div class="entry row" v-for="kv in anime.filter(e => e.key != 'undefined')" :key="kv.key">
        <div class="col-md-6 col-sm-12">{{kv.key}}</div>
        <div class="col-md-6 col-sm-12">
          <div class="btn-group" v-for="group in kv.values" :key="group.key">
            <button class="btn btn-sm btn-secondary" @click="toggle(kv.key, group.key)">{{group.key}}</button>
            <button class="btn btn-sm btn-secondary" @click="download(group.values[group.values.length-1])">{{group.values[group.values.length-1].meta.episode}}</button>
          </div>
        </div>
      </div>
    </div>
</template>

<script>

import * as d3 from 'd3'

const nester = d3.nest()
  .key(d => d.meta ? d.meta.name : undefined)
  .key(d => d.meta ? d.meta.group : undefined)
  .sortKeys(d3.descending)

export default {
  name: 'Main',
  data () {
    return {
      anime: undefined
    }
  },
  mounted () {
    this.$http.get('/api/anime').then(res => {
      this.anime = nester.entries(res.body)
      console.log(this.anime)
    })
  },
  methods: {
    download (torrent) {
      this.$http.post('/api/download', torrent).then(res => {
        console.log(res)
      })
    },
    toggle (name, group) {
      this.$http.post('/api/toggle', { name, group }).then(res => {
        console.log(res)
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
  margin: 0 0.5em;
}
</style>
