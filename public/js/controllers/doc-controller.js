function DocController($scope, $http) {
  $scope.operators = [];
  $scope.predicates = [];
  $scope.aggregators = [];
  $scope.docmode = "examples";
  $http.get('/doc/operators.json').success(function(data) {
    $scope.operators = data;
  });
  $http.get('/doc/predicates.json').success(function(data) {
    $scope.predicates = data;
  });
  $http.get('/doc/aggregators.json').success(function(data) {
    $scope.aggregators = data;
  });
}
