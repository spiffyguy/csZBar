var argscheck = require('cordova/argscheck'),
    exec      = require('cordova/exec');

function ZBar () {};

ZBar.prototype = {

    scan: function (params, success, failure)
    {
        argscheck.checkArgs('*fF', 'CsZBar.scan', arguments);

        params = params || {};
        if(params.text_title === undefined) params.text_title = "Scan QR Code";
        if(params.text_instructions === undefined) params.text_instructions = "Please point your camera at the QR code.";
        if(params.camera != "front") params.camera = "back";
        if(params.flash != "on" && params.flash != "off") params.flash = "auto";
        if(params.scan_multiple != true) params.scan_multiple = false;
        if(params.play_beep != true) params.play_beep = false;
        
        exec(success, failure, 'CsZBar', 'scan', [params]);
    },
	stopScanning: function ()
	{
		exec(success, failure, 'CsZBar', 'stopScanning', null);
	},
	setDisplayText: function (textToDisplay,colorToDisplay,success, failure)
	{
		colorToDisplay= (typeof(colorToDisplay) !== 'undefined') ? colorToDisplay : '';
		success= (typeof(success) !== 'undefined') ? colorToDisplay : function(winParam) {};
		failure= (typeof(failure) !== 'undefined') ? failure : function(error) {};

        params = {text: textToDisplay, color: colorToDisplay};
		exec(success, failure, 'CsZBar', 'setDisplayText', [params]);
	}

};

module.exports = new ZBar;
