angular.module('cube')
.directive('formulaEditor', ['$rootScope', 'data', function($rootScope, data){
  return {
    restrict: 'E',
    templateUrl: 'app/directives/formula-editor.html',
    controller: function($scope){ },
    controllerAs: 'editor'
  };
}]);
