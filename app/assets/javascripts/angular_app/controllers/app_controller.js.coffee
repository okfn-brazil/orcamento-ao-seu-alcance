angular.module('InescApp', ['ui.bootstrap']).controller('AppController', ($scope, $http) ->
  $.getJSON 'http://openspending.org/api/2/aggregate?dataset=inesc&drilldown=orgao|from', (data) ->
    result = []
    data.drilldown.map (element) ->
      # Os órgãos começam do índice 1. Como array começam do 0, tenho que
      # diminuir um elemento, ou o bootstrap tentará acessar um elemento nulo.
      result[element.from.id-1] =
        id: element.from.id
        type: 'from'
        label: element.from.label
      result[element.orgao.id-1] =
        id: element.orgao.id
        type: 'orgao'
        label: element.orgao.label
    $scope.entities = result
)
