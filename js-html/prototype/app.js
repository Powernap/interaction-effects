(function() {
var app = angular.module('cube', [ ]);

// Constructor Code
app.run(function($rootScope, $http) {
  // Load the file containing all servers
  $http.get('config.json')
    .then(function(result){
      // Create rSessions Array
      $rootScope.rSessions = [];
      // and fill it with new Server connections
      result.data.servers.forEach(function(server){
        $rootScope.rSessions.push(new RCUBE.RSession(server.url, server.name));
      });
      $rootScope.dataset = new RCUBE.Dataset(result.data.dataURL);
    });
});

// TODO: This is currently not used, the file input is specified
// in the config.json file. later we may make a custom URL
app.controller('FileloadCtrl', function($scope) {
  this.visible = false;
  // File Changed event from input area
  $scope.file_changed = function(element) {
    var csvFile = element.files[0];
    console.log("Loaded File");
    console.log(csvFile);
    $scope.dataset = new RCUBE.Dataset(csvFile);
  };
});

app.factory('CreateHeatmap', function() {

  // # http://markdalgleish.com/2013/06/using-promises-in-angularjs-views/
  var createHeatmap = function(callback) {
    myRSession = new RCUBE.RSession("http://localhost:1226/ocpu");
    var start = new Date().getTime();
    myRSession.loadDataset("/Users/paul/Desktop/patients-100k.csv", function(session){
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
          callback(myHeatmap);
        });
      });
    });
  };
  return {
    createHeatmap: createHeatmap
  };
});

app.controller("HeatmapController", function($scope, CreateHeatmap){
  var heatmap = this;
  // http://jimhoskins.com/2012/12/17/angularjs-and-apply.html
  // CreateHeatmap.createHeatmap(function(heatmapVis) {
  //   $scope.$apply(heatmap.visible = true);
  //   $scope.heatmapVis = heatmapVis;
  // });
});

})();
