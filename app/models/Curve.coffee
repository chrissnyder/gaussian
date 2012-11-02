_ = require 'lib/underscore'
curves = require 'lib/curves'

class Curve extends Spine.Model
  @configure 'Curve', 'name', 'quarters'

  @fetchAvailableQuarters: (curve) ->
    $.get '/examples/ph/curves/' + curve + '.csv', (curve_data) ->
      $.csv.toObjects curve_data, {}, (err, data) ->
        quarters = _.uniq(_.pluck data, 'quarter')
        grouped_data = _.groupBy data, (datum) ->
          datum.quarter

        Curve.create {name: curve, quarters: grouped_data}
        Curve.trigger 'fetch_quarters', _.sortBy(quarters, ((quarter) -> quarter))

  @fetchQuarterData: (curve, quarter) ->
    curve = Curve.findByAttribute 'name', curve
    quarter_data = curve.quarters[quarter]
    Curve.trigger 'generate_graph', quarter_data


module.exports = Curve