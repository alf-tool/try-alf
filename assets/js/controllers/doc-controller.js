function DocController($scope, $http) {
  var rx = /doc\/(.*)$/g;
  var path = window.location.pathname;
  $scope.current = rx.exec(path)[1] || 'pages/intro';
  console.log($scope.current);
  $scope.docmode = "examples";
}
