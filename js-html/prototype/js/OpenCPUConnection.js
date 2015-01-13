/**
* This class acts as connection to a OpenCPU instance and handles the communication to it.
*
* @class OpenCPUConnection
* @param URL: Url to the OpenCPU Server (e.g. "http://localhost:8054/ocpu")
*/
var OpenCPUConnection = new function(URL) {
	if !("ocpu" in window) {
		console.err("OpenCPU Javascript API is not loaded.");
		return;
	}
	this.URL = URL;
	// Open Connection to URL
	// ocpu.seturl("http://localhost:8054/ocpu/library/utils/R")
	ocpu.seturl(this.URL + "/library/utils/R");
}