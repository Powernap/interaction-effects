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
  var dataset = $rootScope.dataset;
  console.log(dataset);

  dataLoadingService.loadData = function(url) {
    dataset._url = url;
    loadCSV(url, function(csvData){
      dataset.setCsvData(csvData);
      rSessions.loadDataset(url).then(function(data){
        console.log("All Sessions loaded");
        dataset.getDimensionNames().forEach(function(dimensionName){
          rSessions.calculateRSquared(dimensionName).then(function(rSquared){
            dataset._rSquared[dimensionName] = rSquared;
            console.log(dimensionName);
            console.log(rSquared);
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

      // TODO: Respect targetVariable Input
      rsession.calculateRSquaredValues(function(rsquaredSession){
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
          console.log("Loaded for #" + i);
          numberSessionsLoaded = numberSessionsLoaded + 1;
          if (numberSessionsLoaded == rSessionsService.sessions.length)
            resolve();
          // rsession.calculateRSquaredValues(function(rsquaredSession){
          //   $.getJSON(rsquaredSession.loc + "R/.val/json" , function(data){
          //     console.log(data);
          //   });
          // });
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
        console.log($file);
        // rSessions.loadDataset(document.URL + $file.name);
        dataLoading.loadData(document.URL + $file.name);
        // createHeatmap.createHeatmap().then(function(heatmap){ });
      };
    },
    controllerAs: 'myUploader'
  };
}]);

app.factory('createHeatmap', ['$rootScope', '$q', 'rSessions', function($rootScope, $q, rSessions) {

  console.log("createHeatmap Called");
  var createHeatmapService = {};
  createHeatmapService.status = {'created': false};

  var broadcastUpdate = function () {
    $rootScope.$broadcast('createHeatmap.status.update');
  };

  // # http://markdalgleish.com/2013/06/using-promises-in-angularjs-views/
  // var createHeatmap = function(csvUrl, callback) {
  //   var start = new Date().getTime();
  //   myRSession.loadDataset(csvUrl, 'FALSE', function(session){
  //     myRSession.calculateRSquaredValues(myRSession._datasetSession, function(_session){
  //       var end = new Date();
  //       var time = (end.getTime() - start) / (1000);
  //       console.log("[" + end.getHours() + ":" + end.getMinutes() + ":" + end.getSeconds() + "] Execution time " + ": " + time + " seconds");
  //       $.getJSON(myRSession._rSquaredSession.loc + "R/.val/json" , function(data){
  //         myRSession._rSquaredJSON = data;
  //         myJSON = data;
  //         // Test: Create RSquared Values
  //         var rSquared = data;
  //         var names = ["gender","age","diab","hypertension","stroke","chd","smoking","bmi"];
  //         myHeatmap = new RCUBE.Heatmap(".my-heatmap", rSquared, names);
  //         callback(myHeatmap);
  //       });
  //     });
  //   });
  // };

  createHeatmapService.createHeatmap = function(url) {
    // Create Promise
    return $q(function(resolve, reject){
      myRSession = rSessions.sessions[0];
      var start = new Date().getTime();
      myRSession.loadDataset("/Users/paul/Desktop/patients-100k.csv", 'FALSE', function(session){
        myRSession.calculateRSquaredValues(myRSession._datasetSession, function(_session){
          var end = new Date();
          var time = (end.getTime() - start) / (1000);
          console.log("[" + end.getHours() + ":" + end.getMinutes() + ":" + end.getSeconds() + "] Execution time " + ": " + time + " seconds");
          $.getJSON(myRSession._rSquaredSession.loc + "R/.val/json" , function(data){
            myRSession._rSquaredJSON = data;
            myJSON = data;
            // Test: Create RSquared Values
            var rSquared = data;
            var names = ["gender","age","diab","hypertension","stroke","chd","smoking","bmi"];
            myHeatmap = new RCUBE.Heatmap(".my-heatmap", rSquared, names);
            // $rootScope.$apply(createHeatmapService.created = true);
            createHeatmapService.status.created = true;
            console.log("Heatmap created");
            broadcastUpdate();
            resolve(myHeatmap);
          });
        });
      });
    });
  };
  return createHeatmapService;
}]);

app.controller("HeatmapController", function($scope, createHeatmap){
  var heatmap = this;
  // http://jimhoskins.com/2012/12/17/angularjs-and-apply.html
  // https://variadic.me/posts/2013-10-15-share-state-between-controllers-in-angularjs.html
  heatmap.visible = createHeatmap.status.created;
  $scope.$on('createHeatmap.status.update', function () {
    console.log("Got Status update");
    heatmap.visible = createHeatmap.status.created;
  });
});

})();
