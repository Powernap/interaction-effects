(function() {
var app = angular.module('cube', ['flow']);

// Constructor Code
app.run(['$rootScope', '$http', 'ocpuBridge', function($rootScope, $http, ocpuBridge) {
  $rootScope.dataset = new RCUBE.Dataset();
  // Load the file containing all servers
  $http.get('config.json')
    .then(function(result){
      // and fill it with new Server connections
      result.data.servers.forEach(function(server){
        // $rootScope.ocpuBridge.push(new RCUBE.RSession(server.url, server.name));
        ocpuBridge.pushService(server.url, server.name);
      });
      // $rootScope.dataset = new RCUBE.Dataset(result.data.dataURL);
    });
}]);

app.config(['flowFactoryProvider', function (flowFactoryProvider) {
  flowFactoryProvider.defaults = {
    target: '/upload',
    // Test Chunks looks for already uploaded chunks before
    // uploading them again. This may be suitable for large data sets
    testChunks: true,
    progressCallbacksInterval: 0,
    permanentErrors:[404, 500, 501]
  };
  // You can also set default events:
  flowFactoryProvider.on('catchAll', function (event) {
    // Uncomment to see all Flow Events
    // console.log('catchAll', arguments);
  });
}]);

app.factory('createHeatmap', ['$rootScope', '$q', 'data', function($rootScope, $q, data) {

  var createHeatmapService = {};
  createHeatmapService.status = {'created': false};

  createHeatmapService.getStatus = function(){
    return createHeatmapService.status['created'];
  };

  createHeatmapService.createHeatmap = function(dependentVariable){
    var names = data.dataset.getDimensionNames();
    var rSquared = data.dataset._rSquared[dependentVariable];
    myHeatmap = new RCUBE.Heatmap(".my-heatmap", rSquared, names);
    this.status.created = true;
  }

  return createHeatmapService;
}]);

app.controller("HeatmapController", function($scope, createHeatmap){
  var heatmap = this;
  // http://jimhoskins.com/2012/12/17/angularjs-and-apply.html
  // https://variadic.me/posts/2013-10-15-share-state-between-controllers-in-angularjs.html
  heatmap.visible = createHeatmap.status.created;

  $scope.$on('rSquaredCalculationDone', function(event, dimension){
    if (dimension == 'age')
      createHeatmap.createHeatmap('age');
  });

  // https://stackoverflow.com/questions/15380140/service-variable-not-updating-in-controller
  $scope.$watch(createHeatmap.getStatus, function(){
    heatmap.visible = createHeatmap.status.created;
  });
});

})();
