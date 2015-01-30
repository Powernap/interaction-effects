angular.module('cube')
.directive('heatmap', ['data', function(data){
  return {
    restrict: 'E',
    templateUrl: 'app/directives/heatmap.html',
    controller: function($scope){
      var heatmapController = this;
      this.dependent = undefined;
      heatmapController.visible = false;
      // http://jimhoskins.com/2012/12/17/angularjs-and-apply.html
      // https://variadic.me/posts/2013-10-15-share-state-between-controllers-in-angularjs.html
      // https://stackoverflow.com/questions/15380140/service-variable-not-updating-in-controller

      var createHeatmap = function(dependentVariable){
        // Remove old Heatmap container
        $('.my-heatmap svg').remove();
        var names = data.dataset.getDimensionNames();
        var rSquared = data.dataset._rSquared[dependentVariable];
        myHeatmap = new RCUBE.Heatmap(".my-heatmap", rSquared, names);
        heatmapController.visible = true;
      }

      // Dependent
      this.dependentOptions = [];
      $scope.dependentSelect = this.dependentOptions[0];
      $scope.rSquaredValues = data.getRSquaredValues();
      $scope.$watchCollection('rSquaredValues', function(newValue){
        console.log($scope.dependentSelect);
        var values = Object.keys(newValue);
        // Set Heatmap to visible when we actually have rSquared values to display
        if (values.length > 0) {
          heatmapController.visible = true;
          // Only add last new entry to the select to keep the old ones
          var newEntry = values[values.length - 1]
          heatmapController.dependentOptions.push({label: newEntry, value: newEntry});
        }
      });

      this.changeDependent = function(){
        console.log($scope.dependentSelect);
        this.currentDimension = $scope.dependentSelect.label;
        createHeatmap($scope.dependentSelect.label);
      }
    },
  controllerAs: 'heatmap'
};
}]);
