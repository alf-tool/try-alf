function DocController($scope, $http, $stateParams) {
  $scope.doc = [];
  $scope.current = $stateParams['obj'] || 'intro';
  $scope.docmode = "examples";
  $http.get('/doc.json').success(function(data) {
    $scope.doc = data;
  });
}
