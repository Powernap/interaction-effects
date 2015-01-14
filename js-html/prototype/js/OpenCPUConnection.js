/**
* This class acts as connection to a OpenCPU instance and handles the communication to it.
*
* @class OpenCPUConnection
* @param URL: Url to the OpenCPU Server (e.g. "http://localhost:8054/ocpu")
*/
var OpenCPUConnection = function(URLToOpenCPUServer) {
	if (!("ocpu" in window)) {
		console.err("OpenCPU Javascript API is not loaded.");
		return;
	}
	this._URLToOpenCPUServer = URLToOpenCPUServer;
};

OpenCPUConnection.prototype.execute = function(namespace, command, parameters, callbackSuccess, callbackFail) {
	if (parameters == undefined) parameters = {};
	ocpu.seturl(this._URLToOpenCPUServer + namespace)
	ocpu.call(command, parameters, function(session){
		if (callbackSuccess != undefined) callbackSuccess(session);
	}).fail(function(){
		if (callbackFail != undefined) callbackFail(req);
	});
}
