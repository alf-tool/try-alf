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
    .state('blog', {
        url: "/blog/{page:.*}",
        templateUrl: "/blog.html",
    })
    .state('about', {
        url: "/about/",
        templateUrl: "/about.html",
    });
});

tryalf.filter('atob', function() {
  return function(input) {
    return btoa(input);
  };
});

tryalf.run(
  [ '$rootScope', '$state', '$stateParams',
  function ($rootScope, $state, $stateParams) {
    $rootScope.$state = $state;
    $rootScope.$stateParams = $stateParams;
  }]);
