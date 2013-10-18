'use strict';

var tryalf = angular.module('tryalf', ['ui.state', 'ui.ace']);

tryalf.config(function($locationProvider){
  $locationProvider.html5Mode(true);
});

tryalf.config(function($stateProvider, $urlRouterProvider){
  $urlRouterProvider.otherwise("/");
  $stateProvider
    .state('try', {
        url: "/?src",
        templateUrl: "/try.html",
    })
    .state('cheatsheet', {
        url: "/cheatsheet/",
        templateUrl: "/cheatsheet.html",
    })
    .state('doc', {
        url: "/doc/{obj:.*}",
        templateUrl: "/doc.html",
    })
    .state('about', {
        url: "/about/",
        templateUrl: "/about.html",
    });
});

tryalf.filter('markdown', function() {
  return function(input) {
    markdown.toHTML(input);
  };
});

tryalf.run(
  [ '$rootScope', '$state', '$stateParams',
  function ($rootScope, $state, $stateParams) {
    $rootScope.$state = $state;
    $rootScope.$stateParams = $stateParams;
  }]);
