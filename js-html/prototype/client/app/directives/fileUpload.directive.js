angular.module('cube')
.directive('fileUpload', ['$rootScope', 'createHeatmap', 'data', function($rootScope, createHeatmap, data){
  return {
    restrict: 'E',
    templateUrl: 'app/directives/file-upload.html',
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
        data.loadData(document.URL + $file.name);
        // createHeatmap.createHeatmap().then(function(heatmap){ });
      };
    },
    controllerAs: 'myUploader'
  };
}]);
