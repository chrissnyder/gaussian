
curves = require 'lib/curves'

Curve = require 'models/Curve'

class Options extends Spine.Controller
  
  selected_curve: null
  selected_quarter: null

  elements:
    '.curve_selector': 'curve_selector'
    '.quarter_selector': 'quarter_selector'

  events:
    'change .curve_selector': 'onCurveSelection'
    'change .quarter_selector': 'onQuarterSelection'
    'click .less': 'onLessOrders'
    'click .more': 'onMoreOrders'

  constructor: ->
    super
    Curve.bind 'fetch_quarters', @renderQuarters
    @render()

  render: =>
    options = @fillOptions()
    @append require('views/select_curve')({options: options})

  renderQuarters: (quarters) =>
    quarters = @fillQuartersOptions quarters
    if @quarter_selector.html()?
      @quarter_selector.html require('views/select_quarter')({quarters: quarters})
    else
      @append require('views/select_quarter')({quarters: quarters})

  fillOptions: ->
    select_options = []
    for curve in curves
      select_options.push require('views/option_curve')({curve: curve})

    select_options

  fillQuartersOptions: (quarters) ->
    quarter_options = []
    for quarter in quarters
      quarter_options.push require('views/option_quarter')({quarter: quarter})
    quarter_options

  onCurveSelection: (e) ->
    @selected_curve = $(e.currentTarget).val()
    Curve.fetchAvailableQuarters @selected_curve

  onQuarterSelection: (e) ->
    @selected_quarter = $(e.currentTarget).val()
    Curve.fetchQuarterData @selected_curve, @selected_quarter

  onLessOrders: (e) ->
    e.preventDefault()
    Spine.trigger 'less_orders'

  onMoreOrders: (e) ->
    e.preventDefault()
    Spine.trigger 'more_orders'

module.exports = Options