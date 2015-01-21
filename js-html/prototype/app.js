(function() {
var app = angular.module('cube', [ ]);

app.factory('CreateHeatmap', function() {

  // # http://markdalgleish.com/2013/06/using-promises-in-angularjs-views/
  var createHeatmap = function(callback) {
    myRSession = new RCUBE.RSession("http://localhost:1226/ocpu");
    var start = new Date().getTime();
    myRSession.loadDataset("/Users/paul/Desktop/patients-100k.csv", function(session){
      myRSession.calculateRSquaredValues(myRSession._datasetSession, function(_session){
        // _session.getConsole(function(outtxt){console.log(outtxt)});
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
  CreateHeatmap.createHeatmap(function(heatmapVis) {
    $scope.$apply(heatmap.visible = true);
    $scope.heatmapVis = heatmapVis;
  });
});

})();
