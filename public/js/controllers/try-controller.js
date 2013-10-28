function TryController($scope, $stateParams, $http, $filter, $window) {

  $scope.mode     = "data";
  $scope.error    = "";
  $scope.src      = "";
  $scope.result   = "";
  $scope.format   = "text/plain";

  $scope.init = function(){
    $http.get('/doc.json').success(function(data) {
      $scope.examples = data['examples'];
    });
    if ($stateParams.src) {
      $scope.src = atob($stateParams.src);
    }
    $scope.editor.focus();
  }

  $scope.aceLoaded = function(editor) {
    $scope.editor = editor;
    editor.getSession().setTabSize(2);
    $scope.init();
  };

  $scope.getQueryAtRandom = function(){
    var item = null;
    while (!item || item.source == $scope.src){
      items = $scope.examples;
      item  = items[Math.floor(Math.random()*items.length)];
    }
    $scope.src = item.source;
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

  $scope.bookmark = function(){
    var qry = $filter("atob")($scope.src);
    $window.location = "/?src=" + qry;
  }
}
