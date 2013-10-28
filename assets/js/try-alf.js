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

tryalf.factory('Page', function(){
  var title = 'default';
  return {
    title: function() { return $("h1").first().text(); },
  };
});

tryalf.run(
  [ '$rootScope', '$state', '$stateParams', 'Page',
  function ($rootScope, $state, $stateParams, Page) {
    $rootScope.$state = $state;
    $rootScope.$stateParams = $stateParams;
    $rootScope.Page = Page;
  }]);
