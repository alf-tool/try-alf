function DocController($scope, $http) {
  $scope.operators = [];
  $scope.docmode = "examples";
  $http.get('/doc/operators.json').success(function(data) {
    $scope.operators = data;
  });
}
