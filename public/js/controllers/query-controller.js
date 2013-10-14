function QueryController($scope, $stateParams, $http, $filter) {

  $scope.mode     = "data";
  $scope.error    = "";
  $scope.src      = "";
  $scope.query    = {};
  $scope.result   = "";
  $scope.format   = "text/plain";

  $scope.init = function(){
    if ($stateParams.src) {
      $scope.src = $stateParams.src;
      $scope.query = {human: "Type your query below..."}
    } else {
      $scope.getQueryAtRandom();
    }
  }
  
  $scope.setQuery = function(q){
    $scope.src = q['query'];
  }

  $scope.runQuery = function(){
    if ($scope.src) {
      $http({
        method: 'POST',
        url: "/query/" + $scope.mode,
        data: $scope.src,
        headers: { "Accept": $scope.format }
      }).success(function(data){
        if ($scope.format == "application/json") {
          data = $filter('json')(data);
        }
        $scope.result = data;
        $scope.error = "";
      }).error(function(data){
        $scope.error = data;
        $scope.result = "";
      });
    }
  }
  $scope.$watch("format", $scope.runQuery);
  $scope.$watch("mode",   $scope.runQuery);
  $scope.$watch("src",    $scope.runQuery);

  $scope.getQueryAtRandom = function(){
    $http.get("/one").success(function(data){
      $scope.query = data;
      $scope.src = data["alternatives"][0]['query'];
    });
  }
  
  $scope.aceLoaded = function(editor) {
    $scope.editor = editor;
    editor.getSession().setTabSize(2);
    $scope.init();
  };
}
