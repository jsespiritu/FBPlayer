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

package view{
	
	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	import flash.geom.*;
	import model.Model;
	import controller.*;
	import view.*;
	import ui.*;
	import flash.ui.Mouse;
	
	import flash.system.LoaderContext;
	import org.openvideoplayer.rss.*;
	// use for calling javascript function
	import flash.external.ExternalInterface;

	/**
	 * Akamai Multi Player - generates the control bar view, including the play, pause, fullscreen, share, and playlist buttons, as well as the volume and scrub-bar controls.
	 */
	public class ControlbarView extends MovieClip {


		private var _model:Model;
		private var _controller:ControlbarController;
		private var _background:MovieClip;
		
		private var _container:MovieClip;
		private var _playButton:PlayButton;
		private var _pauseButton:PauseButton;
		private var _fullscreenButton:FullscreenButton;
		private var _shareButton:ShareButton;
		private var _playlistButton:PlaylistHorizontalButton;
		private var _volumeControl:VolumeControlView;
		private var _HDmeter:HDMeter2View;
		private var _scrubBar:ScrubBarView;
		private var _toolTip:ToolTipView;
		private var _themeTransform:ColorTransform;
		private var _b6b6b6Transform:ColorTransform;
		
		// added by jerwin s. espiritu
		private var _pixelButton:SettingsButton;
		private var _genericPixelButton:GenericPixelButton;
		private var _currentField:TextField;
		private var _groupListButton:GroupListButton;
		private var _videoModeButton:VideoModeButton;
		//private var _captionButton:CaptionButton;
		private var _cinemaModeButton:CinemaModeButton;
		private var _subtitleButton:SubtitleButton;
		private var _popOutButton:PopUp;
		private var _continousPlayButton:ContinousPlayButton;
		
		private var _pixelView:PixelView;
		private var _popUpView:PopUpView;
		private var _volumeSlider:VolumeSliderView;
		
		private var _backwardButton:BackwardButton;
		private var _forwardButton:ForwardButton;
		private var _currentIndex:uint = 0;
		private var _items:Array;
		private var _movieId:String;
		//private var _captionOnOff:Boolean = false;
		private var _cinemaOnOff:Boolean = false;
		private var _subtitleOnOff:Boolean = false;
		private var _continousPlayOnOff:Boolean = true;
		private var _setPixelSetting:String = "360p";
		private var _previousPixelSetting:String;
		
		private var pixelButtonName:TextField = new TextField();
		private	var pixelTextFormat:TextFormat = new TextFormat();
		
		
		// ----------------------- end 

		public function ControlbarView(model:Model):void {
			_model = model;
			_model.addEventListener(_model.EVENT_PROGRESS, progressiveUpdate);
			_model.addEventListener(_model.EVENT_RESIZE, resize);
			_model.addEventListener(_model.EVENT_SHOW_CONTROLS, showHandler);
			_model.addEventListener(_model.EVENT_HIDE_CONTROLS, hideHandler);
			_model.addEventListener(_model.EVENT_HIDE_FULLSCREEN, fullscreenHandler);
			_model.addEventListener(_model.EVENT_SHOW_PAUSE, showPauseHandler);
			_model.addEventListener(_model.EVENT_END_OF_ITEM, endOfItemHandler);
			_model.addEventListener(_model.EVENT_ENABLE_CONTROLS, enableHandler);
			_model.addEventListener(_model.EVENT_DISABLE_CONTROLS, disableHandler);
			_controller = new ControlbarController(_model,this);
			createChildren();
			this.visible = !_model.isOverlay;
			// Add pixel button
			_pixelButton = new SettingsButton();			
			_pixelButton.addEventListener(MouseEvent.MOUSE_DOWN,pixelMouseDown);
			_pixelButton.addEventListener(MouseEvent.MOUSE_UP, pixelMouseUp);			
			_pixelButton.addEventListener(MouseEvent.CLICK, togglePixel);
			_pixelButton.y =6;
			_container.addChild(_pixelButton);				
			
		}
		
		private function progressiveUpdate(e:Event){
			_setPixelSetting = _model.currentPixelSetting;
			if(_setPixelSetting != _previousPixelSetting)
			{
				_previousPixelSetting = _model.currentPixelSetting;
				
				/*  progressive update for pixel setting label */
				pixelButtonName.embedFonts = true;
				pixelTextFormat.font = new AkamaiArialBold().fontName;
				pixelTextFormat.size = 11;
				pixelTextFormat.bold = 1;
				pixelTextFormat.color = _model.fontColor
				pixelButtonName.defaultTextFormat = pixelTextFormat;
				pixelButtonName.text = _previousPixelSetting;
				pixelButtonName.width = 50;
				pixelButtonName.height = 20;
				pixelButtonName.x = 10;
				pixelButtonName.y = 10;
				_pixelButton.addChild(pixelButtonName);	
			}
		}
		
		private function createChildren():void {
			_background = new MovieClip();
			addChild(_background);
			_container = new MovieClip();
			addChild(_container);
			
			// Define color transforms
			_themeTransform = new ColorTransform();
			_themeTransform.color = _model.themeColor;
			_b6b6b6Transform = new ColorTransform();
			_b6b6b6Transform.color = 0xB6B6B6;
			// Add playbutton
			_playButton = new PlayButton();
			//_playButton.highlight.transform.colorTransform = _themeTransform;
			//_playButton.highlight.alpha = 0;
			//_playButton.addEventListener(MouseEvent.MOUSE_OVER,buttonMouseOver);
			//_playButton.addEventListener(MouseEvent.MOUSE_OUT,buttonMouseOut);
			_playButton.addEventListener(MouseEvent.MOUSE_DOWN,genericMouseDown);
			_playButton.addEventListener(MouseEvent.MOUSE_UP,genericMouseUp);
			_playButton.addEventListener(MouseEvent.CLICK,doPlay);
			_playButton.x = 10;
			_playButton.y = 6;
			_playButton.visible = !_model.autoStart;
			_container.addChild(_playButton);
			// Add pausebutton
			_pauseButton = new PauseButton();
//			_pauseButton.highlight.transform.colorTransform = _themeTransform;
//			_pauseButton.highlight.alpha = 0;
//			_pauseButton.addEventListener(MouseEvent.MOUSE_OVER,buttonMouseOver);
//			_pauseButton.addEventListener(MouseEvent.MOUSE_OUT,buttonMouseOut);
			_pauseButton.addEventListener(MouseEvent.MOUSE_DOWN,genericMouseDown);
			_pauseButton.addEventListener(MouseEvent.MOUSE_UP,genericMouseUp);
			_pauseButton.addEventListener(MouseEvent.CLICK,doPause);
			_pauseButton.x = 10;
			_pauseButton.y = 6;
			_pauseButton.visible = _model.autoStart;
			_container.addChild(_pauseButton);
			//Add fullscreen button
			_fullscreenButton = new FullscreenButton();
//			_fullscreenButton.addEventListener(MouseEvent.MOUSE_OVER,genericMouseOver);
//			_fullscreenButton.addEventListener(MouseEvent.MOUSE_OUT, genericMouseOut);
			_fullscreenButton.addEventListener(MouseEvent.MOUSE_DOWN,genericMouseDown);
			_fullscreenButton.addEventListener(MouseEvent.MOUSE_UP, genericMouseUp);
			_fullscreenButton.addEventListener(MouseEvent.CLICK,toggleFullscreen);
			_fullscreenButton.y = 6;
			_fullscreenButton.visible = _model.enableFullscreen;
			_container.addChild(_fullscreenButton);
			//Add share button
			_shareButton = new ShareButton();
			_shareButton.addEventListener(MouseEvent.MOUSE_OVER,genericMouseOver);
			_shareButton.addEventListener(MouseEvent.MOUSE_OUT, genericMouseOut);
			_shareButton.addEventListener(MouseEvent.MOUSE_DOWN,genericMouseDown);
			_shareButton.addEventListener(MouseEvent.MOUSE_UP, genericMouseUp);
			_shareButton.addEventListener(MouseEvent.CLICK,toggleShare);
			_shareButton.x = 250;
			_shareButton.y = 6;
			_container.addChild(_shareButton);
			//Add playlist button
			_playlistButton = new PlaylistHorizontalButton();
			_playlistButton.addEventListener(MouseEvent.MOUSE_OVER,genericMouseOver);
			_playlistButton.addEventListener(MouseEvent.MOUSE_OUT, genericMouseOut);
			_playlistButton.addEventListener(MouseEvent.MOUSE_DOWN,genericMouseDown);
			_playlistButton.addEventListener(MouseEvent.MOUSE_UP, genericMouseUp);
			_playlistButton.addEventListener(MouseEvent.CLICK, togglePlaylist);
			_playlistButton.x = 300;
			_playlistButton.y = 6;
			_container.addChild(_playlistButton);
			// Add HDMeter
			_HDmeter = new HDMeter2View(_model);
			_HDmeter.y = 6;
			_container.addChild(_HDmeter);
			// Add volume control
/*			_volumeControl = new VolumeControlView(_model);
			_volumeControl.y = 12;
			_container.addChild(_volumeControl);
*/			// Add scrub bar
			_scrubBar = new ScrubBarView(_model);
//			_scrubBar.x = 70;
//			_scrubBar.y = 9;
			_scrubBar.x = 0;
			_scrubBar.y = 40;
			_container.addChild(_scrubBar);
			// added by jerwin s. espiritu
			
			_volumeSlider = new VolumeSliderView(_model);
			_volumeSlider.y = 10;
			_container.addChild(_volumeSlider);
		
			_groupListButton = new GroupListButton();
			_groupListButton.y = 6;
			_groupListButton.addEventListener(MouseEvent.MOUSE_OVER,genericMouseOver);
			_groupListButton.addEventListener(MouseEvent.MOUSE_OUT, genericMouseOut);			
			_groupListButton.addEventListener(MouseEvent.MOUSE_DOWN,genericMouseDown);
			_groupListButton.addEventListener(MouseEvent.MOUSE_UP, genericMouseUp);			
			_groupListButton.addEventListener(MouseEvent.CLICK, toggleGroupList);
			_container.addChild(_groupListButton);

/*			_captionButton = new CaptionButton();
			_captionButton.highlight.transform.colorTransform = _themeTransform;
			_captionButton.highlight.alpha = 0;
			_captionButton.addEventListener(MouseEvent.MOUSE_DOWN,genericMouseDown);
			_captionButton.addEventListener(MouseEvent.MOUSE_UP,genericMouseUp);
			_captionButton.addEventListener(MouseEvent.CLICK,toggleCaption);
			_captionButton.y = 6;
			_container.addChild(_captionButton);
*/			
			_backwardButton = new BackwardButton();
//			_backwardButton.highlight.transform.colorTransform = _themeTransform;
//			_backwardButton.highlight.alpha = 0;
//			_backwardButton.addEventListener(MouseEvent.MOUSE_OVER,buttonMouseOver);
//			_backwardButton.addEventListener(MouseEvent.MOUSE_OUT,buttonMouseOut);
			_backwardButton.addEventListener(MouseEvent.MOUSE_DOWN,genericMouseDown);
			_backwardButton.addEventListener(MouseEvent.MOUSE_UP,genericMouseUp);
			_backwardButton.addEventListener(MouseEvent.CLICK,doBackHandler);
			_backwardButton.y = 6;
			_container.addChild(_backwardButton);

			_forwardButton = new ForwardButton();
//			_forwardButton.highlight.transform.colorTransform = _themeTransform;
//			_forwardButton.highlight.alpha = 0;
//			_forwardButton.addEventListener(MouseEvent.MOUSE_OVER,buttonMouseOver);
//			_forwardButton.addEventListener(MouseEvent.MOUSE_OUT,buttonMouseOut);
			_forwardButton.addEventListener(MouseEvent.MOUSE_DOWN,genericMouseDown);
			_forwardButton.addEventListener(MouseEvent.MOUSE_UP,genericMouseUp);
			_forwardButton.addEventListener(MouseEvent.CLICK,doForward);
			_forwardButton.y = 6;
			_container.addChild(_forwardButton);
			
			_continousPlayButton = new ContinousPlayButton();
//			_continousPlayButton.addEventListener(MouseEvent.MOUSE_OVER,genericMouseOver);
//			_continousPlayButton.addEventListener(MouseEvent.MOUSE_OUT, genericMouseOut);			
			_continousPlayButton.addEventListener(MouseEvent.MOUSE_DOWN,genericMouseDown);
			_continousPlayButton.addEventListener(MouseEvent.MOUSE_UP, genericMouseUp);			
			_continousPlayButton.addEventListener(MouseEvent.CLICK, toggleContinousPlay);
			_continousPlayButton.y =6;
			_container.addChild(_continousPlayButton);
			
			_cinemaModeButton = new CinemaModeButton();
			var cinemaModeButtonName:TextField = new TextField();
//			_cinemaModeButton.highlight.transform.colorTransform = _themeTransform;
//			_cinemaModeButton.highlight.alpha = 0;
			_cinemaModeButton.addEventListener(MouseEvent.MOUSE_DOWN,genericMouseDown);
			_cinemaModeButton.addEventListener(MouseEvent.MOUSE_UP,genericMouseUp);
			_cinemaModeButton.addEventListener(MouseEvent.CLICK,toggleCinemaMode);
			
			_container.addChild(_cinemaModeButton);
						
			_subtitleButton = new SubtitleButton();
			
//			_subtitleButton.highlight.transform.colorTransform = _themeTransform;
//			_subtitleButton.highlight.alpha = 0;
//			_subtitleButton.addEventListener(MouseEvent.MOUSE_DOWN,genericMouseDown);
//			_subtitleButton.addEventListener(MouseEvent.MOUSE_UP,genericMouseUp);
			_subtitleButton.addEventListener(MouseEvent.CLICK,toggleSubtitle);
			_container.addChild(_subtitleButton);
			
			_popOutButton = new PopUp();
/*			var popOutButtonName:TextField = new TextField();
			popOutButtonName.embedFonts = true;
			var popOutTextFormat:TextFormat = new TextFormat();
			popOutTextFormat.font = new AkamaiArialBold().fontName;
			popOutTextFormat.size = 12;
			popOutTextFormat.bold = 1;
			popOutTextFormat.color = _model.fontColor
			popOutButtonName.defaultTextFormat = popOutTextFormat;
			popOutButtonName.text = "Pop out";
			popOutButtonName.width = 50;
			popOutButtonName.height = 20;
			popOutButtonName.x = 10;
			popOutButtonName.y = 1;
			_popOutButton.addChild(popOutButtonName);			
			
			_popOutButton.highlight.transform.colorTransform = _themeTransform;
			_popOutButton.highlight.alpha = 0;
			_popOutButton.addEventListener(MouseEvent.MOUSE_DOWN,genericMouseDown);
			_popOutButton.addEventListener(MouseEvent.MOUSE_UP,genericMouseUp);
*/			_popOutButton.addEventListener(MouseEvent.CLICK,togglePopUp);
			_container.addChild(_popOutButton);
			
			if(!_model.hasPlaylist){
				_forwardButton.visible = false;
				_backwardButton.visible = false;
			}
			if(!_model.isPlayable){
				_playButton.width = 0;
				_playButton.visible = false;
				_pauseButton.visible = false;
				_pauseButton.width = 0;
				_forwardButton.visible = false;
				_forwardButton.width = 0;
				_backwardButton.visible = false;
				_backwardButton.width = 0;
			}
			// -------------- end
			// Add tooltip
			_toolTip = new ToolTipView(_model);
			_toolTip.register(_cinemaModeButton, "Cinema Mode");
			_toolTip.register(_continousPlayButton, "Continous Play");
//			_toolTip.register(_captionButton, "Caption");
			_toolTip.register(_groupListButton, "Playlist");
			_toolTip.register(_subtitleButton, "Subtitle");
			_toolTip.register(_popOutButton, "Pop out");
			//_toolTip.register(_pixelButton, "Video Settings");
			_toolTip.register(_fullscreenButton, "Full Screen");
			_toolTip.register(_playlistButton , "Playlist");
			_toolTip.register(_shareButton, "Share|Embed");
			//_toolTip.register(_HDmeter, "HD Meter");
			_toolTip.register(_HDmeter, "Current Bitrate");
			_container.addChild(_toolTip);
		}
		
		// added by jerwin s. espiritu
				
		private function pixelMouseDown(evt:Event):void{
			_pixelButton.x += 1;
			_pixelButton.y += 1;
			_controller.playClickSound();
		}
		private function pixelMouseUp(evt:Event):void{
			_pixelButton.x -= 1;
			_pixelButton.y -= 1;			
		}		
		private function togglePixel(e:MouseEvent):void {
			_controller.togglePixel();
			_model.hideGroupList();
		}
		private function toggleGroupList(e:MouseEvent):void {
			_controller.toggleGroupList();
			//_groupListHideButton.visible = false;
			_model.hideSettings();
		}

		private function togglePopUp(e:MouseEvent):void {
			_controller.togglePopUp();
			_model.hideSettings();
			_model.hideGroupList();
		}
		private function doBack(e:MouseEvent):void {
			_playButton.visible = true;
			_pauseButton.visible = false;
			_controller.pause();			
		}
		private function doBackHandler(e:MouseEvent): void 
		{
			_items = _model.playlistItems;
			
			if(stage.displayState == StageDisplayState.FULL_SCREEN)
			{
				stage.displayState = StageDisplayState.NORMAL;
			}
			
			for(var i:uint=0; i < _items.length; i++){
				if(ItemTO(_items[i]).media.getContentAt(0).url == _model.src){
					_currentIndex = i;
				}
			}
			var x:uint = (_currentIndex == 0) ? _items.length - 1: _currentIndex - 1;
			_playButton.visible = false;
			_pauseButton.visible = true;
			
			_model.src = ItemTO(_items[x]).media.getContentAt(0).url;
			
			// call changeData javascript function
			_movieId = ItemTO(_items[x]).author;			
			//changeData(_movieId); // =======================================================
			_model.overrideAutoStart=_model.overrideAutoStart==0?0:2;
			_model.playStart();
		}		
		private function doForward(e:MouseEvent):void {
			_items = _model.playlistItems;
			
			if(stage.displayState == StageDisplayState.FULL_SCREEN)
			{
				stage.displayState = StageDisplayState.NORMAL;
			}
			
			for(var i:uint=0; i < _items.length; i++){
				if(ItemTO(_items[i]).media.getContentAt(0).url == _model.src){
					_currentIndex = i;
				}
			}
			
			var x:uint;
			x = (_currentIndex == _items.length - 1) ? 0: _currentIndex + 1;
			
			_playButton.visible = false;
			_pauseButton.visible = true;
		
			_model.src = ItemTO(_items[x]).media.getContentAt(0).url;
			// call changeData javascript function
			_movieId = ItemTO(_items[x]).author;
			 changeData(_movieId); // ===================================================
			_model.overrideAutoStart = _model.overrideAutoStart==0?0:2;
			_model.playStart();
		}
		
		private function changeData(id:String):void{
			if(ExternalInterface.available)
			{
				ExternalInterface.call("changeData(" + id + ")");
			}
		}
		
/*		private function toggleCaption(e:Event):void{
			_controller.toggleCaption();
			_captionOnOff = !_captionOnOff;
			_captionButton.highlight.alpha = _captionOnOff ? 1:0;
			
		}
*/		
		private function toggleCinemaMode(e:MouseEvent):void{
			ExternalInterface.call("cinemaMode()");
			_model.hideSettings();
			_model.hideGroupList();			
			_cinemaOnOff = !_cinemaOnOff;
			_cinemaModeButton.highlight.alpha = _cinemaOnOff ? 1:0;			
		}
		private function toggleSubtitle(e:MouseEvent):void{
			_model.hideSettings();
			_model.hideGroupList();			
			_subtitleOnOff = !_subtitleOnOff;
			_subtitleButton.highlight.alpha = _subtitleOnOff ? 1:0;
		}
		
		private function toggleContinousPlay(e:MouseEvent):void{
			_model.hideSettings();
			_model.hideGroupList();			
			_continousPlayOnOff = !_continousPlayOnOff;
//			_continousPlayButton.highlight.alpha = _continousPlayOnOff ? 0:1;
			_model.overrideAutoStart = _continousPlayOnOff?0:1;
			trace("TOGGLE Continuous play " + _model.overrideAutoStart);
		}
		// ------------------------ end
		
		private function buttonMouseOver(e:MouseEvent):void {
				e.currentTarget.highlight.alpha = 1;
		}
		private function buttonMouseOut(e:MouseEvent):void {
				e.currentTarget.highlight.alpha = 0;
		}
		private function genericMouseDown(e:MouseEvent):void {
			e.currentTarget.x += 1;
			e.currentTarget.y += 1;
			_controller.playClickSound();
		}
		private function genericMouseUp(e:MouseEvent):void {
			e.currentTarget.x -= 1;
			e.currentTarget.y -= 1;
		}
		private function settingsMouseOver(e:MouseEvent):void{
			//trace('settings mouse over');
		}
		private function settingsMouseOut(e:MouseEvent):void{
			//trace('settings mouse out');
		}
		private function genericMouseOver(e:MouseEvent):void {
			e.currentTarget.icon.transform.colorTransform = _themeTransform;
		}
		private function genericMouseOut(e:MouseEvent):void {
			e.currentTarget.icon.transform.colorTransform = _b6b6b6Transform;
		}
		private function doPlay(e:MouseEvent):void {
			_playButton.visible = false;
			_pauseButton.visible = true;
			_controller.play();
		}
		private function doPause(e:MouseEvent):void {
			_playButton.visible = true;
			_pauseButton.visible = false;
			_controller.pause();
			
		}
		
		private function togglePlaylist(e:MouseEvent):void {
			_controller.togglePlaylist();
		}
		private function toggleFullscreen(e:MouseEvent):void {
			_controller.toggleFullscreen();
		}
		private function toggleShare(e:MouseEvent):void {
			_controller.toggleShare();
		}
		private function endOfItemHandler(e:Event):void {	
			if(!_model.overrideAutoStart)
			{
				_playButton.visible = true;
				_pauseButton.visible = false;				
			}
			else
			{
				_playButton.visible = false;
				_pauseButton.visible = true;				
			}
		}
		private function  showHandler(e:Event):void {
			this.visible = true;
		}
		private function  hideHandler(e:Event):void {
			this.visible = false;
		}
		private function enableHandler(e:Event):void {
			_fullscreenButton.alpha = _playButton.alpha = _pauseButton.alpha = 1.0;
			_fullscreenButton.mouseEnabled = _playButton.mouseEnabled = _pauseButton.mouseEnabled = 
			_fullscreenButton.mouseChildren = _playButton.mouseChildren = _pauseButton.mouseChildren = true;			
		}
		private function disableHandler(e:Event):void {
			_fullscreenButton.alpha = _playButton.alpha = _pauseButton.alpha = 0.25;
			_fullscreenButton.mouseEnabled = _playButton.mouseEnabled = _pauseButton.mouseEnabled = 
			_fullscreenButton.mouseChildren = _playButton.mouseChildren = _pauseButton.mouseChildren = false;	
		}
		private function showPauseHandler(e:Event):void {
			_playButton.visible = false;
			_pauseButton.visible = true;
		}
		private function fullscreenHandler(e:Event): void {
			_fullscreenButton.visible = false;			
			resize(null);
		}
		
		// --------------------------- end
		
		public function resize(e:Event):void  {
			//draw background
			_background.graphics.clear();
			_playlistButton.visible = _model.hasPlaylist;
			_shareButton.visible = _model.hasShareOrEmbed;
			_HDmeter.visible = _model.isMultiBitrate;
			
			
			if (_model.isOverlay) {
				//_background.graphics.beginFill(_model.controlbarOverlayColor,1);
				_background.graphics.beginFill(0X1b2023,1);
				_background.graphics.drawRect(3,_model.height+33-_model.controlbarHeight,_model.width -6 ,_model.controlbarHeight-30);
				_background.graphics.endFill();
				_container.x = 3;
				_container.y = _model.height+33-_model.controlbarHeight;
				//_background.graphics.beginFill(0x141313,1);
				_background.graphics.beginFill(0x272a2b,1);
				_background.graphics.drawRect(3,_model.height+33-_model.controlbarHeight,_model.width -6 ,_model.controlbarHeight-50);
				_background.graphics.endFill();
				_container.x = 3;
				_container.y = _model.height+33-_model.controlbarHeight;
			}
			else {
				_container.x = 0;
				_container.y = _model.height - _model.controlbarHeight;

				if (_model.hasPlaylist && _model.playlistVisible) {
					_background.graphics.beginFill(_model.frameColor);
					_background.graphics.drawRect(0,_model.height-_model.controlbarHeight,_model.width - _model.playlistWidth -7,_model.controlbarHeight);
					_background.graphics.endFill();
				} else {
					_background.graphics.beginFill(_model.frameColor);
					_background.graphics.drawRect(0,_model.height-_model.controlbarHeight,_model.width ,_model.controlbarHeight);
					_background.graphics.endFill();
				}
			}
			
			var availableWidth:Number = _model.width - (_model.isOverlay ? 0:(_model.hasPlaylist && _model.playlistVisible) ? _model.playlistWidth+6:0) - 6;

			_playlistButton.width = 0;
			_playlistButton.visible = false;
			_volumeSlider.setWidth(10);
			
			/* Top Video Display*/
//			_cinemaModeButton.x = availableWidth - 6 - _cinemaModeButton.width;
//			_cinemaModeButton.y = (_model.height/4) - _model.height;
//			_subtitleButton.x = availableWidth - 6 - _subtitleButton.width;
//			_subtitleButton.y = (_model.height/4) - _model.height + 30;
//			_popOutButton.x = availableWidth - 6 - _popOutButton.width;
//			_popOutButton.y = (_model.height/4) - _model.height + 60;
			_cinemaModeButton.visible = false;
			_subtitleButton.visible = false;
			_popOutButton.visible = false;
			
			/* Left Control Bar */
			_backwardButton.x = availableWidth - availableWidth + 35;
			_forwardButton.x = availableWidth - availableWidth + 65; 
			_volumeSlider.x = (_model.hasPlaylist)?availableWidth - availableWidth + 145:availableWidth - availableWidth + 65; 

			/* Right Control Bar*/
			_fullscreenButton.x = availableWidth - 40;
			_continousPlayButton.x = availableWidth - 90;
			_groupListButton.x = availableWidth - 140;
			
			/* Disable button below */
			_continousPlayButton.visible = false;
			_groupListButton.visible = false;
			
			
			if(_model.isDynamic)
			{
				_HDmeter.x = availableWidth - 250;
				_pixelButton.visible = false;
				_pixelButton.width = 0;
			}
			else
			{
				//_pixelButton.x = availableWidth - 200;
				_pixelButton.visible = false;
			}
			
			
			
			/* Scrub Bar Position*/
			_scrubBar.y = -4;
			_scrubBar.setWidth(_model.width);
		}
	}
}

