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
	import flash.geom.*;
	import flash.text.*;
	import model.Model;
	import controller.*;

	/**
	 * Akamai Multi Player - generates the scrub bar view as a compilation of the current progress, download progress, scrub head, current time and 
	 * total time controls. 
	 */
	public class ScrubBarView extends MovieClip {


		private var _model:Model;
		private var _controller:ScrubBarController;
		private var _maxLength:Number;
		private var _currentTimeDisplay:TextField;
		private var _totalTimeDisplay:TextField;
		private var _currentProgress:MovieClip;
		private var _downloadProgress:MovieClip;
		private var _scrubber:MovieClip;
		private var _dragging:Boolean;
		private var _background:MovieClip;
		private var _scrubberBar:MovieClip;
		private var _enabled:Boolean;
		//private var _progressBarColor:Number = 0xf26202;
		private var _progressBarColor:Number = 0xeefbff;
		private var _leftLabelXPosition:Number;
		private var _rightLabelXPosition:Number;
		private var _timeFrameLabel:MovieClip;
		private var _timeFrameTextLabel:TextField;

		public function ScrubBarView(model:Model):void {
			_model=model;
			
//			_leftLabelXPosition = (_model.hasPlaylist)?140:60;
//			_rightLabelXPosition = (_model.hasPlaylist)?180:100;
			_leftLabelXPosition = (_model.hasPlaylist)?180:100;
			_rightLabelXPosition = (_model.hasPlaylist)?220:140;
			
			_controller=new ScrubBarController(_model,this);
			addEventListener(Event.ADDED_TO_STAGE, addReleaseOutsideHandler);
			addEventListener(MouseEvent.MOUSE_DOWN, clickHandler);
			_model.addEventListener(_model.EVENT_PROGRESS, progressHandler);
			_model.addEventListener(_model.EVENT_BUFFER_FULL, bufferFullHandler);
			_model.addEventListener(_model.EVENT_NEW_SOURCE, newSourceHandler);
			_model.addEventListener(_model.EVENT_CLOSE_AFTER_PREVIEW,closeAfterPreviewHandler);
			_model.addEventListener(_model.EVENT_ENABLE_CONTROLS, enableHandler);
			_model.addEventListener(_model.EVENT_DISABLE_CONTROLS, disableHandler);
			
			createChildren();
		}
		private function clickHandler(e:MouseEvent):void{
			_scrubber.x = _scrubberBar.mouseX;
		}
		
		private function addReleaseOutsideHandler(e:Event):void {
			 stage.addEventListener(MouseEvent.MOUSE_UP, doOnReleaseOutside);
		}
		
		private function enableHandler(e:Event):void {
			enable();
		}
		
		private function disableHandler(e:Event):void {
			enable(false);
		}
		
		private function enable(value:Boolean=true):void {
			_enabled = value;
			_scrubberBar.mouseEnabled = _scrubberBar.mouseChildren = 
				_downloadProgress.mouseEnabled = _downloadProgress.mouseChildren = 
				_currentProgress.mouseEnabled = _currentProgress.mouseChildren = 
				_scrubber.mouseEnabled = _scrubber.mouseChildren = value;
			alpha = value ? 1.0 : 0.25;
		}
		
		private function createChildren():void {
			_timeFrameLabel = new MovieClip();
			_timeFrameTextLabel = new TextField();
			
			_background = new MovieClip();
			_background.addEventListener(MouseEvent.MOUSE_MOVE, getTimeFrame);
			_background.addEventListener(MouseEvent.MOUSE_DOWN,scrubberDown);
			_background.addEventListener(MouseEvent.MOUSE_UP, scrubberUp, true);
			_background.addEventListener(MouseEvent.MOUSE_OUT, hideTimeFrame);
			_background.useHandCursor = true;
			_background.buttonMode = true;
			addChild(_background);
			
			_scrubberBar = new MovieClip();
			_scrubberBar.addEventListener(MouseEvent.MOUSE_MOVE, getTimeFrame);
			_scrubberBar.addEventListener(MouseEvent.MOUSE_OUT, hideTimeFrame);
			_scrubberBar.useHandCursor = true;
			_scrubberBar.buttonMode = true;
			addChild(_scrubberBar);
			 _dragging = false;
			 _enabled = true;
			// Add current time display
			 _currentTimeDisplay = new TextField()
			 _currentTimeDisplay.embedFonts = true;
			 _currentTimeDisplay.defaultTextFormat = _model.defaultTextFormat;
			 _currentTimeDisplay.autoSize=TextFieldAutoSize.RIGHT;
			 _currentTimeDisplay.multiline = false;
			 _currentTimeDisplay.wordWrap = false;
			 _currentTimeDisplay.text="Waiting / ";
			 _currentTimeDisplay.selectable=false;
			 _currentTimeDisplay.antiAliasType=flash.text.AntiAliasType.ADVANCED;
//			 _currentTimeDisplay.x=0;
//			 _currentTimeDisplay.y=0;
			 _currentTimeDisplay.x=_leftLabelXPosition;
			 _currentTimeDisplay.y=15;
			 addChild(_currentTimeDisplay);
			 // Add total time display
			 _totalTimeDisplay = new TextField()
			 _totalTimeDisplay.embedFonts = true;
			 _totalTimeDisplay.defaultTextFormat = _model.defaultTextFormat;
			 _totalTimeDisplay.autoSize=TextFieldAutoSize.LEFT;
			 _totalTimeDisplay.multiline = false;
			 _totalTimeDisplay.wordWrap = false;
			 _totalTimeDisplay.text="";
			 _totalTimeDisplay.selectable=false;
			 _totalTimeDisplay.antiAliasType=flash.text.AntiAliasType.ADVANCED;
			_totalTimeDisplay.x = _rightLabelXPosition;
			_totalTimeDisplay.y = 15;
			addChild(_totalTimeDisplay);
			 // Add download progress
			 _downloadProgress = new MovieClip();
			 _downloadProgress.addEventListener(MouseEvent.MOUSE_DOWN,scrubberDown);
			 _downloadProgress.addEventListener(MouseEvent.MOUSE_UP, scrubberUp, true);
			 _downloadProgress.addEventListener(MouseEvent.MOUSE_MOVE, getTimeFrame);
			 _downloadProgress.addEventListener(MouseEvent.MOUSE_OUT, hideTimeFrame);
			 //_downloadProgress.graphics.beginFill(_model.themeColor,.3);
			 _downloadProgress.graphics.beginFill(_progressBarColor,.3);
			 _downloadProgress.graphics.drawRect(0,-2,1,8);
			 _downloadProgress.graphics.endFill();
//			 _downloadProgress.x = 96;
			 _downloadProgress.x = 0;
			 _downloadProgress.y = -5;
			 _downloadProgress.useHandCursor = true;
			 _downloadProgress.buttonMode = true;
			 addChild(_downloadProgress);
			  // Add current progress
			 _currentProgress = new MovieClip();
			 _currentProgress.addEventListener(MouseEvent.MOUSE_DOWN,scrubberDown);
			 _currentProgress.addEventListener(MouseEvent.MOUSE_UP, scrubberUp, true);
			 _currentProgress.addEventListener(MouseEvent.MOUSE_MOVE, getTimeFrame);
			 _currentProgress.addEventListener(MouseEvent.MOUSE_OUT, hideTimeFrame);
			 //_currentProgress.graphics.beginFill(_model.themeColor);
			 _currentProgress.graphics.beginFill(_progressBarColor);
			 _currentProgress.graphics.drawRect(0,-2,1,8);
			 _currentProgress.graphics.endFill();
//			 _currentProgress.x = 96;
			 _currentProgress.x = 0;
			 _currentProgress.y = -5;
			 _currentProgress.useHandCursor = true;
			 _currentProgress.buttonMode = true;
			 _currentProgress.addEventListener(Event.ENTER_FRAME,updateCurrentProgress);
			 addChild(_currentProgress);
			 // Add scrubber
			 _scrubber = new MovieClip();
			 //_scrubber.graphics.beginFill(0xAAAAAA);
//			 _scrubber.graphics.beginFill(_progressBarColor);
//			 _scrubber.graphics.drawRect(0,0,7,12);
			 
			 _scrubber.graphics.beginFill(0x808587);
			 _scrubber.graphics.drawCircle(0,4,7);
			 _scrubber.graphics.beginFill(0xdde6e8);
			 _scrubber.graphics.drawCircle(0,Number("4.3"),5);
			 
			 _scrubber.graphics.endFill();
			 _scrubber.addEventListener(MouseEvent.MOUSE_DOWN,scrubberDown);
			 _scrubber.addEventListener(MouseEvent.MOUSE_UP, scrubberUp, true);
			 _scrubber.useHandCursor = true;
			 _scrubber.buttonMode = true;
			 //_scrubber.x = 96;
			 _scrubber.x = 0;
			 _scrubber.y = -7;
			 addChild(_scrubber);

		}
		private function newSourceHandler(e:Event):void {
			_currentTimeDisplay.text = "Loading";
		}
		private function closeAfterPreviewHandler(e:Event):void {
			_currentTimeDisplay.text = "00:00";
		}
		private function scrubberDown(e:MouseEvent):void {
			//_scrubber.startDrag(false,new Rectangle(95,3,_maxLength-7,0));
			_scrubber.startDrag(false,new Rectangle(1,-7,_maxLength-7,0));
			_dragging = true;
		}
		private function scrubberUp(e:MouseEvent):void {
			_scrubber.stopDrag();
			//var t:Number = (_scrubber.x - 95) * _model.streamLength / (_maxLength -7);
			var t:Number = (_scrubber.x - 1) * _model.streamLength / (_maxLength -7);
			_controller.seek(t);
		}

		private function getTimeFrame(e:Event)
		{
			var t:Number = (_scrubberBar.mouseX - 1) * _model.streamLength / (_maxLength -7);
			var tc:String = (t)?this.timeCode(t):"00:00";
			var timeStrCount:Number = tc.length + (tc.length>7?35:25);
			
			_timeFrameLabel.graphics.clear();
			_timeFrameLabel.graphics.beginFill(0xFF6600);
			_timeFrameLabel.graphics.drawRoundRect(0,0,timeStrCount,20,15,15);
			_timeFrameLabel.graphics.endFill();
			_timeFrameLabel.x = _scrubberBar.mouseX;
			_timeFrameLabel.y = -30;
			addChild(_timeFrameLabel);
			_timeFrameLabel.visible = true;

			_timeFrameTextLabel.embedFonts = true;
			_timeFrameTextLabel.mouseEnabled = false;
			_timeFrameTextLabel.selectable = false;
			_timeFrameTextLabel.wordWrap = false;
			_timeFrameTextLabel.selectable = false;
			_timeFrameTextLabel.antiAliasType = flash.text.AntiAliasType.ADVANCED;
			_timeFrameTextLabel.width = timeStrCount;
			var _labelTextFormat:TextFormat = new TextFormat();
			_labelTextFormat.font = new AkamaiLCD().fontName;
			_labelTextFormat.size = 10;
			_labelTextFormat.align = TextFormatAlign.RIGHT;
			_labelTextFormat.color = 0xffffff;// 0xcccccc; _model.themeColor
			_timeFrameTextLabel.defaultTextFormat = _labelTextFormat;
			var tcXPosition:Number = _scrubberBar.mouseX - tc.length + (tc.length>7?4:2);
			_timeFrameTextLabel.x = tcXPosition;
			_timeFrameTextLabel.y = -28;
			_timeFrameTextLabel.text = tc;
			addChild(_timeFrameTextLabel);
			_timeFrameTextLabel.visible = true;
			//trace("_model.timeAsTimeCode === " + tc + " ---- " + timeStrCount);
		}
		
		private function hideTimeFrame(e:MouseEvent)
		{
			_timeFrameLabel.visible = false;
			_timeFrameTextLabel.visible = false
		}
		
		private function timeCode(sec:Number):String {
			var h:Number = Math.floor(sec/3600);
			var m:Number = Math.floor((sec%3600)/60);
			var s:Number = Math.floor((sec%3600)%60);
			return (h == 0 ? "":(h<10 ? "0"+h.toString()+":" : h.toString()+":"))+(m<10 ? "0"+m.toString() : m.toString())+":"+(s<10 ? "0"+s.toString() : s.toString());
		}
		
		private function doOnReleaseOutside(e:MouseEvent):void {
			if (!_enabled) {
				return;
			}
			if (_dragging) {
				scrubberUp(null);
			} else {
				if (!_scrubber.hitTestPoint(e.stageX,e.stageY) && _scrubber.visible) {
//				var topLeft:Point = new Point(95,4);
//				var bottomRight:Point = new Point(95+_maxLength,14);
				var topLeft:Point = new Point(1,4);
				var bottomRight:Point = new Point(1+_maxLength,14);
				if (e.stageX > this.localToGlobal(topLeft).x && 
					e.stageX < this.localToGlobal(bottomRight).x && 
					e.stageY < this.localToGlobal(bottomRight).y && 
					e.stageY > this.localToGlobal(topLeft).y ) {
						_scrubber.x = this.globalToLocal(new Point(e.stageX,e.stageY)).x;
						_dragging = true;
						scrubberUp(null);
					}
				}
			}
		}
		private function progressHandler(e:Event):void {
			if (!isNaN(_model.time) && (_model.isLive || !isNaN(_model.streamLength))) {
				
				_totalTimeDisplay.text = _model.isLive ? "LIVE":_model.streamLengthAsTimeCode;
				_scrubber.visible = _currentProgress.visible = !_model.isLive;
				
				
				if (_model.isBuffering) {
					_currentTimeDisplay.text = _model.bufferPercentage+"% / ";
				} else {
					_currentTimeDisplay.x = _leftLabelXPosition;
					_currentTimeDisplay.y = 15;
					_currentTimeDisplay.text = _model.timeAsTimeCode + " /";
				}

				if (!_dragging) {
//					_scrubber.x = Math.max(95,55 + (_model.time*(_maxLength - 7)/_model.streamLength));
					_scrubber.x = Math.max(-1,0 + (_model.time*(_maxLength - 7)/_model.streamLength));
				}
				if (_model.srcType == _model.TYPE_AMD_PROGRESSIVE || _model.srcType == _model.TYPE_BOSS_PROGRESSIVE) {
					_downloadProgress.width = -1 + _maxLength * _model.bytesLoaded / _model.bytesTotal;
				} else {
					_downloadProgress.width = 0;
				}
			}
		}
		private function bufferFullHandler(e:Event):void {
			_dragging = false;
		}
		private function updateCurrentProgress(e:Event):void {
//			_currentProgress.width = _scrubber.x - 95 + 3;
			_currentProgress.width = _scrubber.x - 1 + 3;
		}
		public function setWidth(w:Number):void {
			//_maxLength = w - 120;
			_maxLength = w-6;
			//_totalTimeDisplay.x= w-60;
			//_totalTimeDisplay.x= 170;


			_background.graphics.beginFill(0x141313);
//			_background.graphics.drawRect(95,4,_maxLength,10);
			_background.graphics.drawRect(-1,-6,_maxLength,10);
			_background.graphics.endFill();
			_scrubberBar.graphics.clear();
//			_scrubberBar.graphics.beginFill(0xe8cfcf);
//			_scrubberBar.graphics.drawRect(-1,5,_maxLength,1);
//			_scrubberBar.graphics.endFill();
			
		}

	}
}
