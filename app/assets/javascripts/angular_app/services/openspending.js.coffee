angular.module('InescApp').factory('openspending', ['$http', '$q', ($http, $q) ->
  url = 'http://openspending.org/api/2'
  aggregateUrl = "#{url}/aggregate?callback=JSON_CALLBACK"
  dataset = "inesc"


  get = (entity, year) ->
    parameters =
      dataset: dataset
    parameters.cut = "#{entity.type}:#{entity.id}" if entity.type

    autorizadoParameters =
      dataset: parameters.dataset
      cut: "time.year:#{year}"
      drilldown: "time.month"
      order: "time.month:asc"
    autorizadoParameters.cut += "|#{parameters.cut}" if parameters.cut

    pagoParameters =
      measure: "pago"

    rppagoParameters =
      measure: "rp-pago"

    yearlyParameters =
      drilldown: "time.year"
      order: "time.year:asc"

    deferred = $q.defer()

    $q.all([
      $http.jsonp(aggregateUrl, { params: autorizadoParameters }),
      $http.jsonp(aggregateUrl, { params: $.extend(autorizadoParameters, pagoParameters) }),
      $http.jsonp(aggregateUrl, { params: $.extend(autorizadoParameters, rppagoParameters) }),
      $http.jsonp(aggregateUrl, { params: $.extend(parameters, yearlyParameters) })
    ]).then (response) ->
      [autorizado, pago, rppago, yearly] = [response[0].data, response[1].data, response[2].data, response[3].data]
      autorizado = $.extend(autorizado, total: autorizado.summary.amount)
      pago = $.extend(pago, total: pago.summary.pago)
      rppago = $.extend(rppago, total: rppago.summary['rp-pago'])
      pagamentos = total: pago.total + rppago.total
      naoExecutado = total: autorizado.total - pagamentos.total
      amounts =
        autorizado: autorizado
        pago: pago
        rppago: rppago
        pagamentos: pagamentos
        naoExecutado: naoExecutado
        yearly: yearly.drilldown
      deferred.resolve $.extend(entity, amounts)

    deferred.promise

  query: ->
    deferred = $q.defer()
    $http.jsonp("#{aggregateUrl}&dataset=#{dataset}&drilldown=orgao|unidade_orcamentaria").success (data) ->
      result = []
      data.drilldown.map (element) ->
        # Os órgãos começam do índice 1. Como array começam do 0, tenho que
        # diminuir um elemento, ou o bootstrap tentará acessar um elemento nulo.
        result[element.orgao.id-1] =
          id: element.orgao.name
          type: 'orgao'
          label: element.orgao.label
        result[element.unidade_orcamentaria.id-1] =
          id: element.unidade_orcamentaria.name
          type: 'unidade_orcamentaria'
          label: element.unidade_orcamentaria.label
          orgao: result[element.orgao.id-1]
      deferred.resolve(result)
    deferred.promise
  getTotals: ->
    deferred = $q.defer()
    $http.jsonp("#{aggregateUrl}&dataset=#{dataset}&drilldown=time.year").success (data) ->
      years = data.drilldown.map (element) ->
        year: element.time.year
        autorizado: element.amount
      totals =
        years: years
        autorizado: data.summary.amount
      deferred.resolve(totals)
    deferred.promise
  getBrasil: (year) ->
    brasil =
      label: "Brasil"
    get(brasil, year)
  get: get


])
