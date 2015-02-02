angular.module('cube')
  .directive('operatorSelect', function() {
    return {
      restrict: 'E',
      templateUrl: 'app/directives/operator-select.html'
    };
  });
