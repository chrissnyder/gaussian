_ = require 'lib/underscore'

Curve = require 'models/Curve'

class Graph extends Spine.Controller

  constructor: ->
    super

    @order = 0

    @svg = d3.select("#container").append("svg")
      .attr("width", 800)
      .attr("height", 500)
      .append("g")

    @fit_line = @svg.append("path")
      .attr("stroke-width", 2.0)
      .attr("stroke", "#049cdb")
      .attr("fill", "transparent")
      .attr("opacity", 1.0)

    Curve.bind 'generate_graph', @generateGraph
    Spine.bind 'less_orders', @lessOrders
    Spine.bind 'more_orders', @moreOrders

  lessOrders: =>
    @order -= 1
    $('#order').html @order
    @generateGraph @data

  moreOrders: =>
    @order += 1
    $('#order').html @order
    @generateGraph @data

  generateGraph: (data) =>
    @data = data

    for datum in @data
      datum.time = parseFloat datum.time
      datum.brightness = parseFloat datum.brightness
      datum.error = parseFloat datum.error

    @data = @data.slice 0, 700
    @p = [1.0, 1.0, 5.0, 1.0]

    # Do stuff with data
    x_min = _.min @data, (datum) ->
      datum.time
    minimum_time = x_min.time
    x_max = _.max @data, (datum) ->
      datum.time

    x_min_new = 0
    x_max_new = 10
    scale = (x_max.time - x_min.time) / (x_max_new - x_min_new)
    for datum, i in @data
      datum.time = x_min_new + ((datum.time - minimum_time) / scale)

    @x_range = [x_min.time, x_max.time]

    y_min = d3.min(@data, (d) -> d.brightness)
    y_max = d3.max(@data, (d) -> d.brightness)

    @x_scale = d3.scale.linear().range([0, 800]).domain(@x_range);
    @y_scale = d3.scale.linear().range([400, 100])
      .domain([y_min, y_max])

    @line = d3.svg.line()
        .x((d) => @x_scale(d.x))
        .y((d) => @y_scale(d.y))
        .interpolate('cardinal')

    if @datapoints?
      @datapoints.data(@data)
        .transition().duration(750)
        .attr("cx", (d) => @x_scale(d.time))
        .attr("cy", (d) => @y_scale(d.brightness))
    else
      @datapoints = @svg.selectAll("circle")
        .data(@data)
        .enter().append("circle")
        .attr("cx", (d) => @x_scale(d.time))
        .attr("cy", (d) => @y_scale(d.brightness))
        .attr("r", 2)

    if @errorbars?
      @errorbars.data(@data)
        .transition().duration(750)
        .attr("x1", (d) => @x_scale(d.time))
        .attr("x2", (d) => @x_scale(d.time))
        .attr("y1", (d) => @y_scale(d.brightness - d.error))
        .attr("y2", (d) => @y_scale(d.brightness + d.error))
    else
      @errorbars = @svg.selectAll("line")
        .data(data)
        .enter().append("line")
        .attr("x1", (d) => @x_scale(d.time))
        .attr("x2", (d) => @x_scale(d.time))
        .attr("y1", (d) => @y_scale(d.brightness - d.error))
        .attr("y2", (d) => @y_scale(d.brightness + d.error))
        .attr("stroke", "black")
        .attr("stroke-width", 1)
        .attr('opacity', 0.5)

    @do_fit()

  do_fit: =>
    i = 1
    while i <= @order
      @p.push(0.0)
      i += 1

    console.log 'pre-optim', @p
    p0 = @p
    p1 = optimize.fmin @chi2, p0
    console.log 'post-optim', p1
    @draw_fit p1

  draw_fit: (p) =>
    fit_data = []
    test_fit_data = []
    spacer = (@x_range[1] - @x_range[0]) / 500
    i = @x_range[0]

    while i < @x_range[1]
      fit_data.push({x: i, y: @model(p, i)[0]})
      i += spacer
    @fit_line.transition().attr('d', @line(fit_data))

    # for datum, i in @data
    #   unless i % 20
    #     if Math.random() > 0.5
    #       diff = datum.brightness * 0.0001
    #     else
    #       diff = -(datum.brightness * 0.0001)
    #     test_fit_data.push {x: datum.time, y: datum.brightness + diff}
    # @fit_line.transition().attr('d', @line(test_fit_data))

  chi: (p) =>
    chi = []
    # if (Math.abs(p[1]) > (@x_range[1] - @x_range[0]) || p[2] > @x_range[1] || p[2] < @x_range[0])
    #   i = 0
    #   while i < @data.length
    #     chi.push(1e10)
    #     i++
    
    i = 0
    while i < @data.length
      res = (@data[i].brightness - @model(p, @data[i].time)[0]) / @data[i].error
      # res = (@data[i].brightness - @model(p, @data[i].time)[0])
      chi.push res
      i++
    
    chi

  chi2: (p) =>
    c = @chi p
    optimize.vector.dot c, c

  model: (a, x) ->
    result = []
    sig2 = a[1] * a[1]

    norm = a[0] / Math.sqrt(2 * Math.PI * sig2)

    x = optimize.vector.atleast_1d(x)
    a = optimize.vector.atleast_1d(a)

    i = 0
    while i < x.length
      diff = x[i] - a[2]
      result.push(norm * Math.exp(-0.5 * diff * diff / sig2))
      i++

    i = 0
    j = 3
    while j < a.length
      while i < x.length
        result[i] += a[j] * Math.pow(x[i], j - 3)
        i++
      j++

    result


module.exports = Graph