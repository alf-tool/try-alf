'use strict';

var tryalf = angular.module('tryalf', ['ui.state', 'ui.ace']);

tryalf.config(function($locationProvider){
  $locationProvider.html5Mode(true);
});

tryalf.config(function($stateProvider, $urlRouterProvider){
  $urlRouterProvider.otherwise("/try/");
  $stateProvider
    .state('try', {
        url: "/try/",
        templateUrl: "/try.html",
    })
    .state('cheatsheet', {
        url: "/cheatsheet/",
        templateUrl: "/cheatsheet.html",
    })
    .state('about', {
        url: "/about/",
        templateUrl: "/about.html",
    });
});

tryalf.run(
  [ '$rootScope', '$state', '$stateParams',
  function ($rootScope, $state, $stateParams) {
    $rootScope.$state = $state;
    $rootScope.$stateParams = $stateParams;
  }]);
