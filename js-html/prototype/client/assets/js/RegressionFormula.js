(function() {
RCUBE.RegressionFormula = function(formula) {
  this._valid = false;
  this._reconstructedFormula = '';
  this.update(formula);
};

RCUBE.RegressionFormula.prototype.update = function(formula) {
  // Fallback to empty formula
  if (typeof(formula) == 'undefined')
    return;
  this._formula = formula;
  // Regex formulas for variables and operators
  this._regexVariables = /([^\^\+\-\:\*\/\|\s]+)/g;
  this._regexOperators = /([\^\+\-\:\*\/\|])/g;
  // Apply regex to the input formula
  this._variables = formula.match(this._regexVariables);
  this._operators = formula.match(this._regexOperators);
  // Check the formula for validity
  var self = this;
  if (this._variables !== null && this._operators !== null && this._operators.length == this._variables.length - 1) {
    this._valid = true;
    this._variables.forEach(function(variable, index){
      self._reconstructedFormula = self._reconstructedFormula + variable;
      // If it is not the last element, attach the operator
      if (index != self._variables.length - 1)
        self._reconstructedFormula = self._reconstructedFormula + self._operators[index];
    });
  }
};

RCUBE.RegressionFormula.prototype.isValid = function(){
  return this._valid;
};

RCUBE.RegressionFormula.prototype.toString = function(){
  return this._reconstructedFormula;
};
})();
