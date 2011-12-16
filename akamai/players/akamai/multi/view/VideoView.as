//
// Copyright (c) 2009-2010, the Open Video Player authors. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without 
// modification, are permitted provided that the following conditions are 
// met:
//
//    * Redistributions of source code must retain the above copyright 
//		notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above 
//		copyright notice, this list of conditions and the following 
//		disclaimer in the documentation and/or other materials provided 
//		with the distribution.
//    * Neither the name of the openvideoplayer.org nor the names of its 
//		contributors may be used to endorse or promote products derived 
//		from this software without specific prior written permission.
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
package view {	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.media.Video;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.*;
	import flash.external.ExternalInterface;
	import model.Model;
	import controller.*
	import ui.*;
	/**
	 * Akamai Multi Player - renders and scales the video on the stage.
	 */
	public class VideoView extends MovieClip {
		private var _model:Model;
		private var _video:Video;
		private var _defaultImage:Loader;
		private var _playButton:PlayButton;
		private var _buyButton:BuyButton;
		private var _innerShadow:InnerShadow;
		private var _background:MovieClip;
		private var _controller:VideoController;
		private var _availableVideoWidth:Number
		private var _availableVideoHeight:Number
		private var _lastVideoWidth:Number;
		private var _lastVideoHeight:Number;
		
		private var _adMessageTextFieldBG:TextField;  // ad message
		private var _adMessageTextField:TextField;    // ad message

		//transforms used for play button overlay
		private var _themeTransform:ColorTransform;
		private var _b6b6b6Transform:ColorTransform;
		
		public var replayButton:ReplayButton;
		public var replayButtonLink:ReplayButtonLink;
		
		// busy animation
		private var _bufferAnimation:TFCBufferAnimation;
		
		// preroll TFC Ad
		private var _tfcPrerollImg:TFCPreroll;
		private var _tfcPrerollBG;
		private var _tfcMainFrameW:Number = 300;
		private var _tfcMainFrameH:Number = 110;
		private var _tfcPrerollLinkTextField:TextField;		
		private var _tfcPrerollFrame:MovieClip;
		
		public function VideoView(model:Model):void {
			_model = model;
			//this.callLoginModal(); // added by jerwin
			_model.addEventListener(_model.EVENT_RESIZE, resize);
			_model.addEventListener(_model.EVENT_PLAY, removeDefaultImage);
			_controller = new VideoController(_model,this);
			createChildren();
			addEventListener(Event.ADDED_TO_STAGE, addedToStage);
		}
		public function get video():Video {
			return _video;
		}
		public function showVideo():void {
			_video.visible = true;
		}
		public function hideVideo():void {
			_video.visible = false;
		}
		public function displaySpinner(spinner:Boolean = false):void{
			spinner = false;
			_bufferAnimation.visible = spinner;
		}		
		private function addedToStage(event:Event):void {
			
			stage.addEventListener( FullScreenEvent.FULL_SCREEN , exitFullScreen );
		}
		private function exitFullScreen( e : FullScreenEvent = null ):void {
			if (e && !e.fullScreen) {
				addChild(_video);
				stage.addChild(_adMessageTextFieldBG);
				stage.addChild(_adMessageTextField);				
			}
			else {
				stage.addChild(_adMessageTextFieldBG);
				stage.addChild(_bufferAnimation);
				stage.addChild(_adMessageTextField);				
				//_bufferAnimation.x=stage.width/2
				//_bufferAnimation.y=stage.height/2;
				_bufferAnimation.x=stage.fullScreenWidth/2
				_bufferAnimation.y=stage.fullScreenHeight/2;
				_tfcPrerollImg.x=stage.fullScreenWidth/2;
				_tfcPrerollImg.y=stage.fullScreenHeight/2;
				replayButton.x=stage.fullScreenWidth/2
				replayButton.y=stage.fullScreenHeight/2;
				replayButtonLink.x=stage.fullScreenWidth/2
				replayButtonLink.y=stage.fullScreenHeight/2;
			}
		}
		
		/* ad message count down */
		public function displayAdMessage(active:Boolean = false, time:String = ""):void{
			if(Number(time)>0){
				_adMessageTextFieldBG.text = "Your video will start in " + time + " sec.";
				_adMessageTextField.text = "Your video will start in " + time + " sec.";
			}
			_adMessageTextFieldBG.visible = active;
			_adMessageTextField.visible = active;
		}
		
		public function displayTFCPrerollAd(active:Boolean = false):void{
			_tfcPrerollImg.visible = active;
			_tfcPrerollFrame.visible = active;
		}
		
		private function createChildren():void {
			_background = new MovieClip();
			addChild(_background);
			//_video = new Video(320, 240);
			_video = new Video(_model.defVideoWidth, _model.defVideoHeight);
			_video.smoothing = false;
			_video.deblocking = 1;
			_video.x = 3;
			_video.y = 3;
			
			addChild(_video);

			replayButton = new ReplayButton();
			replayButtonLink = new ReplayButtonLink();
			replayButton.addEventListener(MouseEvent.CLICK,replay);
			replayButton.x = _model.width / 2;
			replayButton.y = _model.height / 2;
			replayButton.alpha = .7
			
			replayButton.buttonMode = true;
			
			addChild(replayButton);
			replayButton.visible = false;

			replayButtonLink.addEventListener(MouseEvent.CLICK,gotoTfcSite);
			replayButtonLink.x = _model.width / 2;
			replayButtonLink.y = _model.height / 2;
			replayButtonLink.alpha = .7
			
			replayButtonLink.buttonMode = true;
			
			addChild(replayButtonLink);
			replayButtonLink.visible = false;

			/* For Ads Display Message*/
			_adMessageTextFieldBG = new TextField();
			_adMessageTextFieldBG.embedFonts = true;
			var adMessageTextFormatBG = new TextFormat();
			adMessageTextFormatBG.font = new AkamaiArialBold().fontName;
			adMessageTextFormatBG.size = 12.5;
			adMessageTextFormatBG.bold = 5;
			adMessageTextFormatBG.color = 0x000000;
			_adMessageTextFieldBG.defaultTextFormat = adMessageTextFormatBG;
			_adMessageTextFieldBG.width = 310;
			_adMessageTextFieldBG.height = 20;
			addChild(_adMessageTextFieldBG);
			_adMessageTextFieldBG.visible = false;
			
			_adMessageTextField = new TextField();
			_adMessageTextField.embedFonts = true;
			var adMessageTextFormat = new TextFormat();
			adMessageTextFormat.font = new AkamaiArialBold().fontName;
			adMessageTextFormat.size = 13;
			adMessageTextFormat.bold = 0;
			adMessageTextFormat.color = _model.fontColor;
			_adMessageTextField.defaultTextFormat = adMessageTextFormat;
			_adMessageTextField.width = 310;
			_adMessageTextField.height = 20;
			addChild(_adMessageTextField);			
			_adMessageTextField.visible = false;
			
			_bufferAnimation = new TFCBufferAnimation();
			addChild(_bufferAnimation);
			_bufferAnimation.visible = true;

			_tfcPrerollFrame = new MovieClip();
			_tfcPrerollFrame.graphics.beginFill(0Xffffff);
			_tfcPrerollFrame.graphics.drawRect(1,1,_model.width,_model.height);
			_tfcPrerollFrame.graphics.endFill();
			_tfcPrerollFrame.visible = true;
			addChild(_tfcPrerollFrame);
			
			_tfcPrerollImg = new TFCPreroll();
			_tfcPrerollImg.x = _model.width / 2;
			_tfcPrerollImg.y = _model.height / 2;
			
			var tfcMessage:String = "The following video is brought to you by";
			var tfcMessageFontSize:Number = 14;
			var tfcMessageCharLen:Number = tfcMessage.length;
			var tfcPrerollMessageTextField = new TextField();
			tfcPrerollMessageTextField.embedFonts = true;
			var tfcPrerollTextFormat = new TextFormat();
			tfcPrerollTextFormat.font = new AkamaiArialBold().fontName;
			tfcPrerollTextFormat.size = tfcMessageFontSize;
			tfcPrerollTextFormat.bold = 5;
			tfcPrerollTextFormat.color = 0x2d2d2d;
			tfcPrerollMessageTextField.defaultTextFormat = tfcPrerollTextFormat;
			tfcPrerollMessageTextField.text = tfcMessage;
			tfcPrerollMessageTextField.wordWrap = true;
			tfcPrerollMessageTextField.width = tfcMessageCharLen * tfcMessageFontSize;
			tfcPrerollMessageTextField.height = 20;
			tfcPrerollMessageTextField.x = (_tfcPrerollImg.width / 2) - (tfcPrerollMessageTextField.width/2 + 8);
			tfcPrerollMessageTextField.y = -50;
			_tfcPrerollImg.addChild(tfcPrerollMessageTextField);

			var tfcLink:String = "Visit us at www.tfc.tv";
			var tfcLinkFontSize:Number = 14;
			_tfcPrerollLinkTextField = new TextField();			
			_tfcPrerollLinkTextField.alpha = 1;
			_tfcPrerollLinkTextField.embedFonts = true;
			tfcPrerollTextFormat.size = tfcLinkFontSize;
			tfcPrerollTextFormat.bold = 5;
			_tfcPrerollLinkTextField.defaultTextFormat = tfcPrerollTextFormat;
			_tfcPrerollLinkTextField.text = tfcLink;
			var linkCharLen:Number = tfcLink.length;
			_tfcPrerollLinkTextField.wordWrap = true;
			_tfcPrerollLinkTextField.width = linkCharLen * tfcLinkFontSize;
			_tfcPrerollLinkTextField.height = 20;
			_tfcPrerollLinkTextField.x = (_tfcPrerollImg.width / 2) - (_tfcPrerollLinkTextField.width + 55);
			_tfcPrerollLinkTextField.y = (_tfcPrerollImg.height + 28 ) - _tfcPrerollImg.height;
			_tfcPrerollLinkTextField.addEventListener(MouseEvent.CLICK, gotoTfcSite);
			_tfcPrerollLinkTextField.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			_tfcPrerollLinkTextField.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			_tfcPrerollImg.addChild(_tfcPrerollLinkTextField);
			addChild(_tfcPrerollImg);
			_tfcPrerollImg.visible = true;

			/* end of tfc preroll */
			
			if ( !_model.autoStart )
			{
				if(!_model.isPlayable)
				{
					_bufferAnimation.visible = false;
					_buyButton = new BuyButton();					
					var buttonName:TextField = new TextField();
					buttonName.embedFonts = true;
					var textFormat:TextFormat = new TextFormat();
					textFormat.font = new AkamaiArialBold().fontName;
					textFormat.size = 15;
					textFormat.color = _model.fontColor
					buttonName.defaultTextFormat = textFormat;
					buttonName.text = "BUY";
					buttonName.width = 50;
					buttonName.height = 20;
					buttonName.x = 17;
					buttonName.y = -1;
					_buyButton.addChild(buttonName);										
					
					_buyButton.addEventListener(MouseEvent.MOUSE_OVER,playMouseOver);
					_buyButton.addEventListener(MouseEvent.MOUSE_OUT,playMouseOut);
					_buyButton.addEventListener(MouseEvent.MOUSE_DOWN,playMouseDown);
					_buyButton.addEventListener(MouseEvent.MOUSE_UP,playMouseUp);
					_buyButton.addEventListener(MouseEvent.CLICK,doBuy);
					_buyButton.scaleX = 3;
					_buyButton.scaleY = 3;
					_buyButton.alpha = .75;
					addChild( _buyButton );
				}
				else
				{
					_defaultImage = new Loader();
					_defaultImage.x = video.x;
					_defaultImage.y = video.y;
					_defaultImage.load( new URLRequest( _model.loadImage ) );
					addChild( _defaultImage );
					
					// Define color transforms
					_themeTransform = new ColorTransform();
					_themeTransform.color = _model.themeColor;
					_b6b6b6Transform = new ColorTransform();
					_b6b6b6Transform.color = 0xB6B6B6;
					
					_playButton = new PlayButton();
					_playButton.addEventListener(MouseEvent.MOUSE_OVER,playMouseOver);
					_playButton.addEventListener(MouseEvent.MOUSE_OUT,playMouseOut);
					_playButton.addEventListener(MouseEvent.MOUSE_DOWN,playMouseDown);
					_playButton.addEventListener(MouseEvent.MOUSE_UP,playMouseUp);
					_playButton.addEventListener(MouseEvent.CLICK,doPlay);
					_playButton.scaleX = 3;
					_playButton.scaleY = 3;
					_playButton.alpha = .75;
					addChild( _playButton );
				}				
			}
				
			_lastVideoWidth = 0;
			_lastVideoHeight = 0;
		}
		
		private function replay(e:MouseEvent):void{	
			_model.endOfShow = false;
			replayButton.visible = false;
			replayButtonLink.visible = false;
			_model.playingState = true;
			_model.play();
		}

		// added by jerwin espiritu
		private function doBuy(e:MouseEvent):void{
			ExternalInterface.call("confirmBuy()");			
		}
		private function callLoginModal():void{
			if(ExternalInterface.available){
				if(!_model.isLoggedIn){
					ExternalInterface.call("doLogin('"+_model.refer+"')");
				}
			}
		}
		private function gotoTfcSite(e:MouseEvent):void{
			navigateToURL( new URLRequest( _model.tfcLink+"/video/"+_model.videoId ) , "_blank" );
		}
		// ends here
		
		public function scaleVideo(width:Number,height:Number):void {
			_lastVideoWidth = width;
			_lastVideoHeight  = height;
			
			if(stage!=null){
				if(stage.displayState == StageDisplayState.FULL_SCREEN){
					video.width = stage.fullScreenWidth;
					video.height = stage.fullScreenHeight;
					video.x=(stage.fullScreenWidth-video.width)/2;
					video.y=(stage.fullScreenHeight-video.height)/2;					
				}
				else{
					s();
				}
			}
			else{
				s();
			}
			function s():void{
				switch (_model.scaleMode) {
					case _model.SCALE_MODE_FIT:
						if (width/height >= _availableVideoWidth/_availableVideoHeight) {
							video.width = _availableVideoWidth;
							video.height = _availableVideoWidth*height/width;
						} else {
							video.width = _availableVideoHeight*width/height;
							video.height = _availableVideoHeight;
						}
						break;
					case _model.SCALE_MODE_STRETCH:
						video.width = _availableVideoWidth;
						video.height = _availableVideoHeight;
						break;
					case _model.SCALE_MODE_NATIVE:
						video.width = width;
						video.height = height;
						break;
					case _model.SCALE_MODE_NATIVE_OR_SMALLER:
						if (width > _availableVideoWidth || height  > _availableVideoHeight) {
							if (width/height >= _availableVideoWidth/_availableVideoHeight) {
								video.width = _availableVideoWidth;
								video.height = _availableVideoWidth*height/width;
							} else {
								video.width = _availableVideoHeight*width/height;
								video.height = _availableVideoHeight;
							}
						} else {
							video.width = width;
							video.height = height;
						}
						break;
				}				
				video.x = 3 + ((_availableVideoWidth - video.width)/2);
				video.y = 3 + ((_availableVideoHeight- video.height)/2);
			}
			
			if ( _defaultImage != null ) {
				_defaultImage.x = 3;
				_defaultImage.y = 3;
				_defaultImage.width = _availableVideoWidth;
				_defaultImage.height = _availableVideoHeight;
				
				_playButton.x = _defaultImage.x + ((_availableVideoWidth - _playButton.width ) /2);
				_playButton.y = _defaultImage.y + ((_availableVideoHeight - _playButton.height ) /2);
			}
			if(!_model.isPlayable)
			{
				_buyButton.x = ((_availableVideoWidth - _buyButton.width ) /2);
				_buyButton.y = ((_availableVideoHeight - _buyButton.height ) /2);	
				_bufferAnimation.visible = false;
			}
			//_bufferAnimation.x = ((_availableVideoWidth - _bufferAnimation.width ) /2) + 30;
			//_bufferAnimation.y = ((_availableVideoHeight - _bufferAnimation.height ) /2) + 20;
			_bufferAnimation.x = _model.width / 2;
			_bufferAnimation.y = _model.height / 2;
			_tfcPrerollImg.x = _model.width / 2;
			_tfcPrerollImg.y = _model.height / 2;
			
		}
		private function resize(e:Event):void  {
			//_availableVideoWidth = _model.width - (_model.isOverlay ? 0:(_model.hasPlaylist && _model.playlistVisible)? _model.playlistWidth+6:0) - 6;
			//_availableVideoHeight = _model.height - (_model.isOverlay ? 0:_model.controlbarHeight) - 6;
			_availableVideoWidth = _model.availableVideoWidth;
			_availableVideoHeight = _model.availableVideoHeight;
//			_innerShadow.width = _model.availableVideoWidth;
//			_innerShadow.height = _model.availableVideoHeight;

			/* overlay position */
			replayButton.x = _model.width / 2;
			replayButton.y = _model.height / 2;
			replayButtonLink.x = _model.width / 2;
			replayButtonLink.y = _model.height / 2;
			
			/* overlay buffer animation */
			_bufferAnimation.x = _model.width / 2;
			_bufferAnimation.y = _model.height / 2;
			
			/* preroll tfc message */
			_tfcPrerollImg.x = _model.width / 2;
			_tfcPrerollImg.y = _model.height / 2;
			
			_background.graphics.clear();
			_background.graphics.beginFill(_model.videoBackgroundColor);
			_background.graphics.drawRect(3,3,_model.availableVideoWidth,_model.availableVideoHeight);
			_background.graphics.endFill();
			scaleVideo(_lastVideoWidth, _lastVideoHeight);
		}
		public function invokeResize() : void {
			if ( _lastVideoWidth == 0 || isNaN( _lastVideoWidth ) || _lastVideoHeight == 0 || isNaN( _lastVideoHeight ) ) {
				scaleVideo(video.videoWidth, video.videoHeight);
			}
		}
		private function removeDefaultImage(e:Event) : void {
			if ( _defaultImage != null )
			{
				_defaultImage.unloadAndStop();
				removeChild( _defaultImage );
				_defaultImage = null;
				
				//removeChild( _playButton );
			}
		}
		private function onMouseOver(e:MouseEvent):void{
			e.currentTarget.alpha = .45;
		}
		private function onMouseOut(e:MouseEvent):void{
			e.currentTarget.alpha = 1;
		}
		private function playMouseOver(e:MouseEvent):void {
				e.currentTarget.highlight.alpha = .45;
		}
		private function playMouseOut(e:MouseEvent):void {
			e.currentTarget.highlight.alpha = 0;
		}
		private function playMouseDown(e:MouseEvent):void {
			e.currentTarget.x += 1;
			e.currentTarget.y += 1;
			_model.playClickSound();
		}
		private function playMouseUp(e:MouseEvent):void {
			e.currentTarget.x -= 1;
			e.currentTarget.y -= 1;
		}
		private function doPlay(e:MouseEvent):void {
			_playButton.visible = false;
			_model.play();
			_model.showPauseButton();
		}
		private function buttonMouseOver(e:MouseEvent):void {
				e.currentTarget.highlight.alpha = 1;
		}
		private function buttonMouseOut(e:MouseEvent):void {
				e.currentTarget.highlight.alpha = 0;
		}
		
	}
}
