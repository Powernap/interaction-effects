angular.module('cube')
  .directive('formulaEditor', ['$rootScope', 'data', function($rootScope, data) {
    return {
      restrict: 'E',
      templateUrl: 'app/directives/formula-editor.html',
      controller: function($scope) {
        // This function is taken straight from the typeahead example page: https://twitter.github.io/typeahead.js/examples/
        var substringMatcher = function(strs) {
          return function findMatches(q, cb) {
            var matches, substrRegex;

            // an array that will be populated with substring matches
            matches = [];

            // regex used to determine if a string contains the substring `q`
            substrRegex = new RegExp(q, 'i');

            // iterate through the pool of strings and for any string that
            // contains the substring `q`, add it to the `matches` array
            $.each(strs, function(i, str) {
              if (substrRegex.test(str)) {
                // the typeahead jQuery plugin expects suggestions to a
                // JavaScript object, refer to typeahead docs for more info
                matches.push({
                  value: str
                });
              }
            });

            cb(matches);
          };
        };

        // Watch the dimension array
        $scope.dimensions = data.dataset.getDimensionNames();
        // Attach typeahead logic to the UI
        $scope.$watchCollection('dimensions', function(dimensions) {
          // Only attach the typeahead logic if there are dimensions available
          if (dimensions.length > 0) {
            // Attach X and Y variables to the dimension list
            // We copy the dimensions list to not interfere with it in other controllers
            var typeaheadDimensions = dimensions.slice(0);
            typeaheadDimensions.splice(0,0, 'x','y');
            $('#formulaInput').textcomplete([
            { // tech companies
                words: typeaheadDimensions,
                match: /\b(\w{0,})$/,
                search: function (term, callback) {
                    callback($.map(this.words, function (word) {
                        var currentWord = word.indexOf(term) === 0 ? word : null;
                        if (currentWord !== null)
                          console.log(currentWord);
                        return word.indexOf(term) === 0 ? word : null;
                    }));
                },
                index: 1,
                replace: function (word) {
                    return word + ' ';
                }
            }
        ]);
            // Remove all prior typeahead instances
            $('.typeahead').typeahead('destroy');
            // And attach the new ones
            $('.typeahead').typeahead({
              hint: true,
              highlight: true,
              minLength: 1
            }, {
              name: 'typeaheadDimensions',
              displayKey: 'value',
              source: substringMatcher(typeaheadDimensions)
            });
          }
        });
      },
      controllerAs: 'editor'
    };
  }]);
