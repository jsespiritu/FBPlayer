//
// Copyright (c) 2009-2010, the Open Video Player authors. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without 
// modification, are permitted provided that the following conditions are 
// met:
//
//    * Redistributions of source code must retain the above copyright 
//notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above 
//copyright notice, this list of conditions and the following 
//disclaimer in the documentation and/or other materials provided 
//with the distribution.
//    * Neither the name of the openvideoplayer.org nor the names of its 
//contributors may be used to endorse or promote products derived 
//from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR 
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY 
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
package
{
    import flash.display.*;
    import flash.events.*;
    import flash.geom.Rectangle;
    import flash.media.Video;
    import flash.system.Capabilities;
	import flash.utils.Timer;
    
    import ui.FullscreenButton;
	import model.Model;
	import view.*;		
	import ui.PlayButtonBig;
    
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;	
	import flash.net.URLLoaderDataFormat;
	/*
     * This example illustrates the invocation of the Akamai Multi Player in a Flash CS4 project. Note that control
     * of the fullscreen behavior is externalized, since in many instances the player component itself may not be the only display object
     * on stage and therefore other layout and positioning methods may have to be called when moving to fullscreen.
     *
     * <p/>
     * Due to Dynamic Streaming Support, this project must be compiled for Flash Player 10 or higher.
     *
     * @see AkamaiMultiPlayer
     */
    public class Player extends MovieClip
    {
		private static const PUBLISHER_PLAYLIST_URL:String = "http://localhost/akamai/players/akamai/multi/orig_feed.xml";
        //private static const PUBLISHER_PLAYLIST_URL:String = "http://localhost/xml/agua.xml";
        private static const MBR_SMIL:String = "http://mediapm.edgesuite.net/ovp/content/demo/smil/elephants_dream.smil";
		//private static const MBR_SMIL:String = "";
		
		//private static const PUBLISHER_PLAYLIST_URL:String = "http://localhost/akamai/players/akamai/multi/feed.xml";
		//private static const MBR_SMIL:String = "http://localhost/multibitrate_vid.smil";
		
        private var player:AkamaiMultiPlayer;
        private var _video:Video;
		private var _model:Model;
		private var _timer:Timer;
        
		private var _playButton:PlayButtonBig;
		private var _videoView:VideoView;
		
		/*   token generator  */
		private var _src:String;
		private var _userId:String;
		private var _clock_txt:String;
		//private var _tokenAPI:String = "http://abscbnhttp.streamguys.com/playerbeta/token/generate_token.php";
		private var _geoIpUrl:String = "http://tfc.tv/video/getip.php";
		private var _tokenAPI:String = "http://204.93.205.209/AkamaiTokenGenerator/token/generate_token.php";
		//private var _geoIpUrl:String = "http://204.93.205.209/GeoIpAPI/geoip_api.php";
		private var _tokenDuration:String = "600";
		private var _tokenAcl:String = "/*";
		private var _tokenKey:String = "1cb57a04160477a119e57791f27a0706";
		private var _qAPI:String = "http://log.solucientinc.com/q/write_to_queue.php";
		private var _tokenParam = "";
		private var _enableLogging:Number = 1;
		private var _enableToken:Number = 1;

        /**
         * Constructor
         */
        public function Player():void{
			var _model:Model;
            stage.addEventListener(FullScreenEvent.FULL_SCREEN, exitFullScreen);
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
			
			if (stage.stageWidth == 0 || stage.stageHeight == 0){
				setStageListeners(onInitStageResize);
            }
            else{
				onInitStageResize(null);
            }
        }
		
        private function onInitStageResize(e:Event):void
        {			
            if (stage.stageWidth > 0 && stage.stageHeight > 0){
				setStageListeners(onInitStageResize, false);
				setStageListeners(onResize);				
								
				_clock_txt = this.getDateTime();

				/* enable the code below to get source xml from api */
				/* start of block */
				var flashvars:Object = loaderInfo.parameters;
				_tokenAPI = flashvars.tokenAPI == undefined ? _tokenAPI : flashvars.tokenAPI;
				//_src = flashvars.src == undefined ? "http://tfctvapphd-f.akamaihd.net/z/smil/tfctv/mmk1.smil/manifest.f4m" : unescape(flashvars.src.toString());
				_src = flashvars.src == undefined ? "" : unescape(flashvars.src.toString());
				_userId = flashvars.userId == undefined ? _userId : flashvars.userId;
				_tokenKey = flashvars.tokenKey == undefined ? _tokenKey : flashvars.tokenKey;
				_tokenDuration = flashvars.tokenDuration == undefined ? _tokenDuration : flashvars.tokenDuration;
				_tokenAcl = flashvars.tokenAcl == undefined ? _tokenAcl : flashvars.tokenAcl;
				_qAPI = flashvars.queueURL == undefined ? _qAPI : flashvars.queueURL;
				_enableLogging = flashvars.enableLogging == undefined ? _enableLogging : Number(flashvars.enableLogging.toString());
				_enableToken = flashvars.enableLogging == undefined ? _enableToken : Number(flashvars.enableToken.toString());
				
				// param Object
				var param:Array = new Array();
				param['startTime'] = _clock_txt;
				param['tokenAPI'] = _tokenAPI;
				param['tokenKey'] = _tokenKey;
				param['tokenDuration']= _tokenDuration;
				param['tokenAcl'] = _tokenAcl;
				param['content_url'] = _src;
				param['userId'] = _userId;
				
				/* reading file */
//				var myTextLoader:URLLoader = new URLLoader();
//				myTextLoader.addEventListener(Event.COMPLETE, onLoaded);
//				myTextLoader.load(new URLRequest("http://tfc.tv/video/myText.xml"));
				/* end reading file */
				
				if(_enableToken>0){
					this.requestToken(param);
				}
				else{
					this.getToken(null);
				}
				/* end of block */

				/* enable the code below if you want to revert back from original code */
				/* start of block */				
//				player = new AkamaiMultiPlayer(stage.stageWidth, stage.stageHeight, loaderInfo.parameters);
//				
//                /* If you want to rely on the src coming in as a flash var,  then comment-out the next line */
//                player.setNewSource(getTestMedia());
//				
//				var flasvars:Object = loaderInfo.parameters;
//				_model = new Model(flasvars);
//				_timer = new Timer(5000,1);
//                player.addEventListener("toggleFullscreen", handleFullscreen);
//                addChild(player);
				/* end of block */
            }
        }

		/* Reading file*/
//		private function onLoaded(e:Event):void {
//    		var myArrayOfLines:Array = e.target.data.split(/\n/);
//			trace("------------------>>>>> " + myArrayOfLines[1]);
//		}
		/* End reading file*/
		
		private function getTestMedia(playlist:Boolean = true):String
		{
			return (playlist) ? PUBLISHER_PLAYLIST_URL : MBR_SMIL;
		}	
		
		private function onResize(event:Event):void
		{		
			player.resizeTo(stage.stageWidth, stage.stageHeight);
		}
        
        private function handleFullscreen(e:Event):void{
            if (stage.displayState == StageDisplayState.NORMAL){
				//remove stage listener here to during fullscreen
				setStageListeners(onResize, false);
				
                _video = new Video();
                _video = player.video;
				           
                _video.width = stage.fullScreenWidth;
                _video.height = stage.fullScreenHeight;
                _video.smoothing = true;
				_video.x=(stage.fullScreenWidth-_video.width)/2;
				_video.y=(stage.fullScreenHeight-_video.height)/2;
				player.addChildAt(_video, stage.numChildren + 1);
				
                stage.displayState = StageDisplayState.FULL_SCREEN;				
				player.resizeTo( stage.fullScreenWidth , stage.fullScreenHeight );

			}
        }
		
		function toggleFullScreen(event:MouseEvent):void{
			if (this.stage.displayState == StageDisplayState.FULL_SCREEN){
				this.stage.displayState=StageDisplayState.NORMAL;
			}
			else{
				this.stage.displayState=StageDisplayState.FULL_SCREEN;	
			}
		}				
        		
        private function exitFullScreen(e:FullScreenEvent = null):void{
            if (e && !e.fullScreen)
            {
				//since we remove the stage listener on fullscreen we add it back here
				setStageListeners(onResize);				
                player.resizeTo(stage.stageWidth, stage.stageHeight);
                stage.displayState = StageDisplayState.NORMAL;
            }
        }
		
		private function setStageListeners(handler:Function, add:Boolean = true):void{
			if (add){
				stage.addEventListener(Event.RESIZE, handler);
			}
			else{
				stage.removeEventListener(Event.RESIZE, handler);
			}
		}
		
		public function requestToken(param:Array):void {			
			var request:URLRequest = new URLRequest(param['tokenAPI']);
			var variables:URLVariables = new URLVariables();
			var urlloader:URLLoader = new URLLoader();
			
			variables.st = param['startTime'];
			variables.key = param['tokenKey'];
			variables.acl = param['tokenAcl'];
			variables.duration = param['tokenDuration'];
			request.data = variables;
			request.method = URLRequestMethod.GET;
			urlloader.load(request);
			urlloader.addEventListener(Event.COMPLETE, getToken);
			urlloader.addEventListener(IOErrorEvent.IO_ERROR, getTokenIOError);
			
			var msg:String = "actiontype" + "~jhe~" + "requesttoken" + "|jhe|" +
							  "content" + "~jhe~" + param['content_url'] + "|jhe|" +
							  "userid" + "~jhe~" + param['userId'] + "|jhe|" +
							  "datetime" + "~jhe~" + this.getDateTime() + "|jhe|" +
							  "otherinfo" + "~jhe~" + "token_key:" + param['tokenKey'] + "\t" + "token_acl:" + param['tokenAcl'] + "\t" + "duration:" + param['tokenDuration'] + "\t" + "start_time:" + param['startTime']; 
			if(_enableLogging>0) this.writeToLog(msg);
		}
		
		private function getToken(event:Event):void{
			var token:String = "";
			var link:String = _src;
			if(_enableToken){
				var loader:URLLoader = URLLoader(event.target);						
				token = loader.data;
				var extension:String = _src.slice(_src.lastIndexOf(".")+1);
				
				if(extension.toLocaleLowerCase() == "f4m"){
					link = _src + "?hdnea=" + token;				
				}
				_tokenParam = "?hdnea=" + token;				
			}
			else{
				_tokenParam = "";
			}
			//token = token;
			//_model.debug("Generated Token: " + loader.data);
			player = new AkamaiMultiPlayer(stage.stageWidth, stage.stageHeight, loaderInfo.parameters, link, _tokenParam);
			
			// If you want to rely on the src coming in as a flash var,  then comment-out the next line
			player.setNewSource(link);
			//
			var flashvars:Object = loaderInfo.parameters;
			_model = new Model(flashvars, link, _tokenParam);
			_model.tokenParam = "?hdnea=" + token;
			_timer = new Timer(5000,1);
			player.addEventListener("toggleFullscreen", handleFullscreen);
			addChild(player);
			player.debug("Generated Token: " + token);
			player.debug("Getting Client Time: " + _clock_txt);
			
			var msg:String = "actiontype" + "~jhe~" + "responsetoken" + "|jhe|" +
							  "content" + "~jhe~" + _src + "|jhe|" +
							  "userid" + "~jhe~" + _userId + "|jhe|" +
							  "datetime" + "~jhe~" + this.getDateTime() + "|jhe|" +
							  "otherinfo" + "~jhe~" + "generated_token:" + token; 
			if(_enableLogging>0) this.writeToLog(msg);			
		} /* end of getToken function */
		
		private function getTokenIOError(event:IOErrorEvent):void {
			player.debug("Unable to generate token.");
		}	

		private function writeToLog(msg:String):void{
			var request:URLRequest = new URLRequest(_qAPI);
			var variables:URLVariables = new URLVariables();
			var urlloader:URLLoader = new URLLoader();
			
			//urlloader.dataFormat = URLLoaderDataFormat;
			variables.msg = msg;
			request.data = variables;
			request.method = URLRequestMethod.POST;
			//urlloader.dataFormat = URLLoaderDataFormat.VARIABLES;
			
			urlloader.load(request);
			urlloader.addEventListener(Event.COMPLETE, urlLoaderHandleComplete);
			urlloader.addEventListener(IOErrorEvent.IO_ERROR, urlLoaderOnIOError);			
		} /* end of writeToLog function */
		
		private function urlLoaderHandleComplete(event:Event):void{
			var loader:URLLoader = URLLoader(event.target);
			//player.debug("Done writing to Queue " + loader.data);
		}
		
		private function urlLoaderOnIOError(event:IOErrorEvent):void {
			//player.debug("Unable to write message to Queue.");
		}
		
		private function getDateTime():String{
			var time:Date = new Date(); // time object
			var year = time.getFullYear();
			var month = time.getMonth() + 1;
			var date = time.getDate();
			var seconds = time.getSeconds();
			var minutes = time.getMinutes();
			var hours = time.getHours();
			var dateTime:String = "";
			if(month<10){
				month = "0" + month;
			}
			if(hours<10){
				date = "0" + date;
			}
			
			if(hours<10){
				hours = "0" + hours;
			}
			if(minutes<10){
				minutes = "0" + minutes;
			}
			if(seconds<10){
				seconds = "0" + seconds;
			}
			
			dateTime = year + "-" + month + "-" + date + " " + hours + ":" + minutes + ":" + seconds + " ";
			return dateTime;			
		} /* end getDateTime function */		
    }
}
