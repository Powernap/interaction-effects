angular.module('cube')
.directive('heatmap', ['data', function(data){
  return {
    restrict: 'E',
    templateUrl: 'app/directives/heatmap.html',
    controller: function($scope){
      var heatmapContainer = this;
      // http://jimhoskins.com/2012/12/17/angularjs-and-apply.html
      // https://variadic.me/posts/2013-10-15-share-state-between-controllers-in-angularjs.html
      // https://stackoverflow.com/questions/15380140/service-variable-not-updating-in-controller

      var createHeatmap = function(dependentVariable){
        var names = data.dataset.getDimensionNames();
        var rSquared = data.dataset._rSquared[dependentVariable];
        myHeatmap = new RCUBE.Heatmap(".my-heatmap", rSquared, names);
        heatmapContainer.visible = true;
      }

      $scope.$on('rSquaredCalculationDone', function(event, dimension){
        if (dimension == 'age')
          createHeatmap('age');
      });
    },
  controllerAs: 'heatmap'
};
}]);
