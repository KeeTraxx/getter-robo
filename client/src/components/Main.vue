<template>
  <div class="container">
    <h1>Main</h1>
    <table class="table table-striped table-hover">
      <thead>
        <tr>
          <th>Title</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="kv in anime.filter(e => e.key != 'undefined')" :key="kv.key">
          <td>{{kv.key}}</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script>

import * as d3 from 'd3'

const nester = d3.nest()
        .key(d => d.meta ? d.meta.name : undefined)
        .key(d => d.meta ? d.meta.episode : undefined)
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
    }
  }
}
</script>
