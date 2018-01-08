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
        <tr v-for="torrent in anime" :key="torrent.guid">
          <td @click="download(torrent)">{{torrent.title}}</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script>
export default {
  name: 'Main',
  data () {
    return {
      anime: undefined
    }
  },
  mounted () {
    this.$http.get('/api/anime').then(res => {
      this.anime = res.body
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
