(function() {
var app = angular.module('cube', ['flow']);

// Constructor Code
app.run(['$rootScope', '$http', 'rSessions', function($rootScope, $http, rSessions) {
  $rootScope.dataset = new RCUBE.Dataset();
  // Load the file containing all servers
  $http.get('config.json')
    .then(function(result){
      // and fill it with new Server connections
      result.data.servers.forEach(function(server){
        // $rootScope.rSessions.push(new RCUBE.RSession(server.url, server.name));
        rSessions.pushService(server.url, server.name);
      });
      // $rootScope.dataset = new RCUBE.Dataset(result.data.dataURL);
    });
}]);

app.factory('dataLoading', ['$rootScope', 'rSessions', function($rootScope, rSessions){
  var dataLoadingService = {};
  dataLoadingService.dataset = $rootScope.dataset;

  dataLoadingService.loadData = function(url) {
    dataLoadingService.dataset._url = url;
    loadCSV(url, function(csvData){
      dataLoadingService.dataset.setCsvData(csvData);
      rSessions.loadDataset(url).then(function(data){
        console.log("Dataset loaded for all active OpenCPU sessions");
        // TODO: All requests are executed in parallel, it will be a good
        // idea to perform it manually
        // dataLoadingService.dataset.getDimensionNames().forEach(function(dimensionName){
        ['age', 'gender'].forEach(function(dimensionName){
          rSessions.calculateRSquared(dimensionName).then(function(rSquared){
            dataLoadingService.dataset._rSquared[dimensionName] = rSquared;
            $rootScope.$broadcast('rSquaredCalculationDone', dimensionName);
          });
        });
      });
    });
  };

  var loadCSV = function(url, callback) {
    d3.csv(url, function(data){
      callback(data);
    });
  };
  return dataLoadingService;
}]);

app.factory('rSessions', ['$q', function($q){
  var rSessionsService = {};
  rSessionsService.sessions = [];

  rSessionsService.calculateRSquared = function(targetVariable){
    return $q(function(resolve, reject){
      // TODO: Write distribution algorithm here!
      var rsession = rSessionsService.sessions[0];

      rsession.calculateRSquaredValues(targetVariable, function(rsquaredSession){
        $.getJSON(rsquaredSession.loc + "R/.val/json" , function(rSquaredData){
          resolve(rSquaredData);
        });
      });
    });
  };

  // This event is called when the user uploads a new data set
  rSessionsService.loadDataset = function(url) {
    return $q(function(resolve, reject){
      var numberSessionsLoaded = 0;
      rSessionsService.sessions.forEach(function(rsession, i){
        rsession.loadDataset(url, function(){
          numberSessionsLoaded = numberSessionsLoaded + 1;
          if (numberSessionsLoaded == rSessionsService.sessions.length)
            resolve();
        });
      });
    });
  };
  rSessionsService.pushService = function(url, name){
    rSessionsService.sessions.push(new RCUBE.RSession(url, name))
    console.log("Created new R Session: " + url + ", " + name);
  };
  return rSessionsService;
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

app.directive('fileUpload', ['$rootScope', 'createHeatmap', 'rSessions', 'dataLoading', function($rootScope, createHeatmap, rSessions, dataLoading){
  return {
    restrict: 'E',
    templateUrl: 'directives/file-upload.html',
    controller: function($scope){
      this.visible = true;
      this.uploadEnabled = false;
      this.progressbar = {
        "visible": false,
        "percent": 0
      }
      this.progressbarVisible = false;
      var controllerSelf = this;
      // Has to be defined on the Scope, because `input`s don't have an angular change event
      // See https://stackoverflow.com/questions/17922557/angularjs-how-to-check-for-changes-in-file-input-fields
      uploader = this;
      $scope.fileNameChanged = function(){
        uploader.uploadEnabled = true;
      };

      $scope.uploader = {};
      this.upload = function() {
        $scope.uploader.flow.upload();
      };

      $scope.uploader.flowUploadStart = function(){
        controllerSelf.progressbar.visible = true;
      };

      $scope.uploader.flowFileProgress = function($file){
        controllerSelf.progressbar.percent = $file.progress() * 100;
      };

      $scope.uploader.flowFileSuccess = function ($flow, $file, $message) {
        // console.log($file);
        // rSessions.loadDataset(document.URL + $file.name);
        dataLoading.loadData(document.URL + $file.name);
        // createHeatmap.createHeatmap().then(function(heatmap){ });
      };
    },
    controllerAs: 'myUploader'
  };
}]);

app.factory('createHeatmap', ['$rootScope', '$q', 'dataLoading', function($rootScope, $q, dataLoading) {

  var createHeatmapService = {};
  createHeatmapService.status = {'created': false};

  createHeatmapService.getStatus = function(){
    return createHeatmapService.status['created'];
  };

  createHeatmapService.createHeatmap = function(dependentVariable){
    var names = dataLoading.dataset.getDimensionNames();
    var rSquared = dataLoading.dataset._rSquared[dependentVariable];
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
