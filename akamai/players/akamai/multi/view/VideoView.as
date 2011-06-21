﻿//
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
		
		//transforms used for play button overlay
		private var _themeTransform:ColorTransform;
		private var _b6b6b6Transform:ColorTransform;
		
		public function VideoView(model:Model):void {
			_model = model;
			this.callLoginModal(); // added by jerwin
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
		private function addedToStage(event:Event):void {
			
			stage.addEventListener( FullScreenEvent.FULL_SCREEN , exitFullScreen );
		}
		private function exitFullScreen( e : FullScreenEvent = null ):void {
			if (e && !e.fullScreen) {
				addChild(_video);
			}
		}
		private function createChildren():void {
			_background = new MovieClip();
			addChild(_background);
			//_video = new Video(320, 240);
			_video = new Video(800, 600);
			_video.smoothing = false;
			_video.deblocking = 1;
			_video.x = 3;
			_video.y = 3;
			
			addChild(_video);
//			_innerShadow = new InnerShadow();
//			_innerShadow.scale9Grid = new Rectangle(5,5,784,584);
//			_innerShadow.x = _innerShadow.y = 3;
//			addChild(_innerShadow);
			
			if ( !_model.autoStart )
			{
				if(!_model.isPlayable)
				{
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
		
		// added by jerwin espiritu
		private function doBuy(e:MouseEvent):void{
			ExternalInterface.call("confirmBuy()");			
		}
		private function callLoginModal():void{
			if(!_model.isLogin){
				ExternalInterface.call("doLogin('"+_model.refer+"')");
			}
		}
		// ends here
		
		public function scaleVideo(width:Number,height:Number):void {
			_lastVideoWidth = width;
			_lastVideoHeight  = height;
			
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
			//_video.smoothing = (width != video.width || height != video.height) && (_model.isFullScreen == false);
			//_model.debug("Smoothing = " + _video.smoothing);
			//_video.smoothing  = false;
			video.x = 3 + ((_availableVideoWidth - video.width)/2);
			video.y = 3 + ((_availableVideoHeight- video.height)/2);
			
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
				
			}
				
		}
		private function resize(e:Event):void  {
			//_availableVideoWidth = _model.width - (_model.isOverlay ? 0:(_model.hasPlaylist && _model.playlistVisible)? _model.playlistWidth+6:0) - 6;
			//_availableVideoHeight = _model.height - (_model.isOverlay ? 0:_model.controlbarHeight) - 6;
			_availableVideoWidth = _model.availableVideoWidth;
			_availableVideoHeight = _model.availableVideoHeight;
//			_innerShadow.width = _model.availableVideoWidth;
//			_innerShadow.height = _model.availableVideoHeight;
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
				
				removeChild( _playButton );
			}
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
	}
}
