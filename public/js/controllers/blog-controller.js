function BlogController($scope, $http, $stateParams) {
  $scope.page = $stateParams['page'] || '2013-10-21-relations-as-first-class-citizen';
}
