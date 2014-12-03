function DocController($scope, $http) {
  var rx = /doc\/(.*)$/g;
  var path = window.location.pathname;
  var match = rx.exec(path);
  $scope.current = (match && match[1]) || 'pages/intro';
  console.log($scope.current);
  $scope.docmode = "examples";
}
