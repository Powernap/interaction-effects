(function() {
var app = angular.module('cube', [ ]);

// app.controller("HeatmapController", ['loadHeatmap' function(loadHeatmap){
//   // console.log("Heatmap in Controller");
//   // console.log(Heatmap);
//
//   // this.visible = true;
// })];

// # http://markdalgleish.com/2013/06/using-promises-in-angularjs-views/

app.factory('CreateHeatmap', function() {

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

app.factory('HelloWorld', function($timeout) {

  var getMessages = function(callback) {
    setTimeout(function() {
      callback(['Hello', 'world!']);
    }, 2000);
  };

  return {
    getMessages: getMessages
  };

});

app.controller("HeatmapController", function($scope, CreateHeatmap){
  var heatmap = this;
  // this.visible = true;
  CreateHeatmap.createHeatmap(function(heatmapVis) {
    console.log("Done!");
    heatmap.visible = true;
    $scope.heatmapVis = heatmapVis;
    console.log($scope.messages);
    $scope.$apply();
  });
});

// app.controller("HeatmapController", function($scope, HelloWorld){
//   var heatmap = this;
//   // this.visible = true;
//   HelloWorld.getMessages(function(messages) {
//     console.log("Done!");
//     heatmap.visible = true;
//     $scope.messages = messages;
//     console.log($scope.messages);
//     $scope.$apply();
//   });
// });

// var dataloaded = true;
//
// var performanceTest = function(id, serverURL) {
//   myRSession = new RCUBE.RSession(serverURL);
//   var start = new Date().getTime();
//   myRSession.loadDataset("/Users/paul/Desktop/patients-100k.csv", function(session){
//     myRSession.calculateRSquaredValues(myRSession._datasetSession, function(_session){
//       // _session.getConsole(function(outtxt){console.log(outtxt)});
//       var end = new Date();
//       var time = (end.getTime() - start) / (1000);
//       console.log("[" + end.getHours() + ":" + end.getMinutes() + ":" + end.getSeconds() + "] Execution time " + id + ": " + time + " seconds");
//       $.getJSON(myRSession._rSquaredSession.loc + "R/.val/json" , function(data){
//         myRSession._rSquaredJSON = data;
//         console.log(data);
//         myJSON = data;
//         // Test: Create RSquared Values
//         var rSquared = data;
//         var names = ["gender","age","diab","hypertension","stroke","chd","smoking","bmi"];
//         var myHeatmap = new RCUBE.Heatmap(".my-heatmap", rSquared, names);
//         dataloaded = true;
//       });
//     });
//   });
// };
// performanceTest(1, "http://localhost:9167/ocpu");
})();
