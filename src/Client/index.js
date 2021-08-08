import { Elm } from './Main.elm'

const app = Elm.Client.Main.init({
  node: document.querySelector('main')
});
