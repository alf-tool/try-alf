'use strict';

var tryIt = function(elm) {
  window.location = "/try?src=" + btoa($(elm).find("code").text());
}

var queryString = function (){
  var query_string = {};
  var query = window.location.search.substring(1);
  var vars = query.split("&");
  for (var i=0;i<vars.length;i++) {
    var pair = vars[i].split("=");
    if (typeof query_string[pair[0]] === "undefined") {
      query_string[pair[0]] = pair[1];
    } else if (typeof query_string[pair[0]] === "string") {
      var arr = [ query_string[pair[0]], pair[1] ];
      query_string[pair[0]] = arr;
    } else {
      query_string[pair[0]].push(pair[1]);
    }
  } 
  return query_string;
};

var tryalf = angular.module('tryalf', ['ui.ace']);

tryalf.config(function($locationProvider){
  $locationProvider.html5Mode(false);
});

tryalf.filter('atob', function() {
  return function(input) {
    return btoa(input);
  };
});

tryalf.run(function($rootScope) {
});

