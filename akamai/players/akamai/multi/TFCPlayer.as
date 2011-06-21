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
    
    /**
     * This example illustrates the invocation of the Akamai Multi Player in a Flash CS4 project. Note that control
     * of the fullscreen behavior is externalized, since in many instances the player component itself may not be the only display object
     * on stage and therefore other layout and positioning methods may have to be called when moving to fullscreen.
     *
     * <p/>
     * Due to Dynamic Streaming Support, this project must be compiled for Flash Player 10 or higher.
     *
     * @see AkamaiMultiPlayer
     */
    public class TFCPlayer extends MovieClip
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
        /**
         * Constructor
         */
        public function TFCPlayer():void
        {
			var _model:Model;
            stage.addEventListener(FullScreenEvent.FULL_SCREEN, exitFullScreen);
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
			
            if (stage.stageWidth == 0 || stage.stageHeight == 0)
            {
				setStageListeners(onInitStageResize);
            }
            else
            {
				onInitStageResize(null);
            }
        }
        
        private function onInitStageResize(e:Event):void
        {
            if (stage.stageWidth > 0 && stage.stageHeight > 0)
            {
				setStageListeners(onInitStageResize, false);
				setStageListeners(onResize);				
                player = new AkamaiMultiPlayer(stage.stageWidth, stage.stageHeight, loaderInfo.parameters);
				
                // If you want to rely on the src coming in as a flash var,  then comment-out the next line
                player.setNewSource(getTestMedia());
				//
				var flasvars:Object = loaderInfo.parameters;
				_model = new Model(flasvars);
				_timer = new Timer(5000,1);
                player.addEventListener("toggleFullscreen", handleFullscreen);
                addChild(player);
            }
        }
		
		private function getTestMedia(playlist:Boolean = true):String
		{
			return (playlist) ? PUBLISHER_PLAYLIST_URL : MBR_SMIL;
		}	
		
		private function onResize(event:Event):void
		{		
			player.resizeTo(stage.stageWidth, stage.stageHeight);
		}
        
        private function handleFullscreen(e:Event):void
        {
            if (stage.displayState == StageDisplayState.NORMAL)
            {
				//remove stage listener here to during fullscreen
				setStageListeners(onResize, false);
				
                _video = new Video();
                _video = player.video;
				
                _video.width = _video.videoWidth;
                _video.height = _video.videoHeight;
                _video.smoothing = false;
                _video.x = 0;
                _video.y = 0;
                stage.addChild(_video);
				
				// handle fullscreen controlbar
				
				//var _container = new MovieClip();
/*				var _background = new MovieClip();
				
				
				_background.graphics.beginFill(0X1b2023,1);
				_background.graphics.drawRect(0,0,40,60);
				_background.graphics.endFill();
				
				_background.y = 220;
				_playButton = new PlayButtonBig();
				_playButton.width = 22;
				_playButton.height = 20;
				_playButton.x = 10;
				_playButton.y = 10;
				_playButton.addEventListener(MouseEvent.CLICK, toggleFullScreen);
				_background.addChild(_playButton);
				this.stage.addChild(_background);*/
				
				
                stage.fullScreenSourceRect = new Rectangle(0, 0, _video.videoWidth, _video.videoHeight);
                stage.displayState = StageDisplayState.FULL_SCREEN;				
            }
//			if(stage.displayState == "fullScreen"){
//				stage.addEventListener(MouseEvent.MOUSE_MOVE,displayControlBar);
//			}
        }
		
		function toggleFullScreen(event:MouseEvent):void
		{
		  if (this.stage.displayState == StageDisplayState.FULL_SCREEN)
		  {
			this.stage.displayState=StageDisplayState.NORMAL;
		  }
		  else
		  {
			this.stage.displayState=StageDisplayState.FULL_SCREEN;	
		  }
		}		
		
//		private function displayControlBar(e:Event):void{
//			_model.enableControls();
//			_model.showControlBar( true );
//		}
        		
        private function exitFullScreen(e:FullScreenEvent = null):void
        {
            if (e && !e.fullScreen)
            {
				//since we remove the stage listener on fullscreen we add it back here
				setStageListeners(onResize);				
                player.resizeTo(stage.stageWidth, stage.stageHeight);
                stage.displayState = StageDisplayState.NORMAL;
            }
        }
		
		private function setStageListeners(handler:Function, add:Boolean = true):void
		{
			if (add)
			{
				stage.addEventListener(Event.RESIZE, handler);
			}else
			{
				stage.removeEventListener(Event.RESIZE, handler);
			}
		}
    }
}
