$(document).ready ->
  autorizadoUrl = "http://openspending.org/api/2/aggregate?dataset=inesc&cut=time.year:2011|from.label:SENADO%20FEDERAL&drilldown=from|time.month&order=time.month:asc"
  pagoUrl = autorizadoUrl + "&measure=pago"

  $.when(
    $.getJSON(autorizadoUrl),
    $.getJSON(pagoUrl)
  ).then (autorizado, pago) ->
     nv.addGraph () ->
         testdata = processData(autorizado, pago)
         window.testdata = testdata
         chart = nv.models.multiChart()
               .margin({top: 30, right: 60, bottom: 50, left: 70})
               .x((d,i) -> i)
               .color(d3.scale.category10().range())
  
         chart.xAxis.tickFormat((d) ->
           dx = testdata[0].values[d] && testdata[0].values[d].x || 0
           d3.time.format('%b')(new Date(dx))
         )
     
         chart.yAxis1.showMaxMin(false)
             .tickFormat(d3.format(',s.2'))
     
         chart.yAxis2.showMaxMin(false)
             .tickFormat((d) -> '$' + d3.format(',f')(d))
     
         d3.select('.graph svg')
             .datum(testdata)
           .transition().duration(500).call(chart)
     
         nv.utils.windowResize(chart.update)
     
         chart
  
  processData = (autorizado, pago) ->
    accumulateAmounts = (values, element) ->
      length = values.length
      amount = if length > 0 then values[length-1].y else 0
      amount += element.amount || element.pago || 0
      values.push {
        x: element.time.month,
        y: amount
      }
      values

    [
      {
        key: "Pagamentos",
        yAxis: 1,
        type: "area",
        values: pago[0].drilldown.map (element) -> { x: element.time.month, y: element.pago }
      },
      {
        key: "Pagamentos Acumulados",
        yAxis: 1,
        type: "line",
        values: pago[0].drilldown.reduce(accumulateAmounts, [])
      },
      {
        key: "Autorizado",
        yAxis: 1,
        type: "area",
        values: autorizado[0].drilldown.reduce(accumulateAmounts, [])
      },
    ]
