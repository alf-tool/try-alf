function QueryController($scope, $http) {

  $scope.mode     = "data";
  $scope.error    = "";
  $scope.src      = "";
  $scope.query    = {};
  $scope.result   = "";
  $scope.format   = "text/plain";
  
  $scope.setQuery = function(q){
    $scope.src = q['query'];
  }
  $scope.runQuery = function(){
    if ($scope.src && $scope.looksOk($scope.src)) {
      $http({
        method: 'POST',
        url: "/query/" + $scope.mode,
        data: $scope.src,
        headers: {
          "Accept": $scope.format
        }
      }).success(function(data){
        $scope.result = data;
        $scope.error = "";
      }).error(function(data){
        $scope.error = data;
        $scope.result = "";
      });
      $scope.editor.focus();
    }
  }

  $scope.looksOk = function(src) {
    return true;
  }
  
  $scope.getQueryAtRandom = function(){
    $http.get("/one").success(function(data){
      $scope.query = data;
      $scope.src = data["alternatives"][0]['query'];
    });
  }
  $scope.$watch("format", function(newValue, oldValue){
    $scope.runQuery();
  });
  $scope.$watch("mode", function(newValue, oldValue){
    $scope.runQuery();
  });
  $scope.$watch("src", function(newValue, oldValue){
    $scope.runQuery();
  });
  
  $scope.aceLoaded = function(editor) {
    $scope.editor = editor;
    editor.getSession().setTabSize(2);
    $scope.getQueryAtRandom();
  };
}
