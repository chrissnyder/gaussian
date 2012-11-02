require 'lib/setup'

Spine = require 'spine'

Curve = require 'models/Curve'

Graph = require 'controllers/graph'
Options = require 'controllers/options'

class App extends Spine.Controller

  constructor: ->
    super

    options = new Options({el: $('.options')})
    graph = new Graph()

module.exports = App
    