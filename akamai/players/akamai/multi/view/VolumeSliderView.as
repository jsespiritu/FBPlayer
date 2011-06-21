
package view{
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import model.Model;
	import controller.*;
	import ui.*;

	public class VolumeSliderView extends MovieClip {
		private var _model:Model;
		private var _controller:VolumeSliderController;
		private var _volumeIcon:VolumeIcon;
		private var _muteState:Boolean;
		private var _lastVolume:Number;
		
		private var _scrubber:MovieClip;
		private var _maxLength:Number;
		private var _dragging:Boolean;
		private var _volLevel:int;
		private var _enabled:Boolean;
		private var _previousVolLevel:Number;
		
		private var _background:MovieClip;
		private var _highlight:MovieClip;
		private var _backgroundWidth:Number = 30;
		private var _volumeBar:MovieClip;
		private var _scrubBarYPosition:Number = -20;
		private var _volumeBarXPosition:Number = 2;
		private var _volumeBarYPosition:Number = -20;
		private var _volumBarWidth:Number = 8;
		private var _maxVolLevel:Number;
		
		private var _volumdBarColor:Number = 0xeefbff;
		
		public function VolumeSliderView(model:Model):void {
			_model=model;
			_controller=new VolumeSliderController(_model,this);
			addEventListener(Event.ADDED_TO_STAGE, addReleaseOutsideHandler);
			_model.addEventListener(_model.EVENT_HIDE_VOLUMEBAR, hideVolumeBar);
			_model.addEventListener(_model.EVENT_PROGRESS, currentVol);
			_model.addEventListener(_model.EVENT_ENABLE_CONTROLS, enableHandler);
			_model.addEventListener(_model.EVENT_DISABLE_CONTROLS, disableHandler);
			
			createChildren();
		}
		
		private function addReleaseOutsideHandler(e:Event):void {
			 stage.addEventListener(MouseEvent.MOUSE_UP, doOnReleaseOutside);
		}
		
		private function doOnReleaseOutside(e:MouseEvent):void {
			if (!_enabled) {
				return;
			}
			if (_dragging) {
				scrubberUp(null);
			} else {
				if (!_scrubber.hitTestPoint(e.stageX,e.stageY) && _scrubber.visible) {
				var topLeft:Point = new Point(95,4);
				var bottomRight:Point = new Point(95+_maxLength,14);
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
		
		private function enableHandler(e:Event):void {
			enable();
		}
		
		private function disableHandler(e:Event):void {
			enable(false);
		}
		
		private function enable(value:Boolean=true):void {
			_enabled = value;
			_volumeBar.mouseEnabled = _volumeBar.mouseChildren = _scrubber.mouseEnabled = _scrubber.mouseChildren = value;
			alpha = value ? 1.0 : 0.25;
		}
		
		private function createChildren():void {

			_background = new MovieClip();
			addChild(_background);
			_background.visible = false;
//			_highlight = new MovieClip();
//			addChild(_highlight);
//			_highlight.visible = false;
			
			_volumeBar = new MovieClip();
			_volumeBar.addEventListener(MouseEvent.CLICK,bgClick);
			_volumeBar.useHandCursor = true;
			_volumeBar.buttonMode = true;
			addChild(_volumeBar);
			_volumeBar.visible = false;
			
			_muteState = _model.volume == 0 ? true : false;
			_dragging = false;
			_enabled = true;
			_lastVolume = 1;

			_volumeIcon=new VolumeIcon() ;
			_volumeIcon.addEventListener(MouseEvent.MOUSE_OVER, displayVolumeLevel);
			_volumeIcon.x=0;
			_volumeIcon.y=0;
			_volumeIcon.addEventListener(MouseEvent.CLICK,handleIconClick);
			if (_muteState) {
				_volumeIcon.transform.colorTransform = new ColorTransform(1,1,1,1,200);
			}
			addChild(_volumeIcon);
						
			 // volume scrubber
			 _scrubber = new MovieClip();
			 _scrubber.graphics.beginFill(0x808587);
			 _scrubber.graphics.drawCircle(4,0,7);
			 _scrubber.graphics.beginFill(0xdde6e8);
			 _scrubber.graphics.drawCircle(Number("4.3"),0,5);
			 _scrubber.graphics.endFill();
			 _scrubber.x = 2;
			 _scrubber.y = _scrubBarYPosition;
			 _scrubber.y = -80;
			 _scrubber.addEventListener(MouseEvent.MOUSE_DOWN,scrubberDown);
			 _scrubber.addEventListener(MouseEvent.MOUSE_UP, scrubberUp, true);
			 _scrubber.useHandCursor = true;
			 _scrubber.buttonMode = true;
			 addChild(_scrubber);			
			_scrubber.visible = false;
		}
		
		private function displayVolumeLevel(e:MouseEvent)
		{
			_scrubber.visible = true;
			_background.visible = true;
			_volumeBar.visible = true;
//			_highlight.visible = true;
		}
		
		private function hideVolumeBar(e:Event)
		{
			_scrubber.visible = false;
			_background.visible = false;
			_volumeBar.visible = false;			
//			_highlight.visible = false;
		}
		
		private function bgClick(e:MouseEvent):void{
			_scrubber.y = _volumeBar.mouseY;
		}
		
		// adjust volume level up
		private function scrubberDown(e:MouseEvent):void {
			_scrubber.startDrag(false,new Rectangle(2,_scrubBarYPosition,0,_maxLength-7));
			_dragging = true;
		}
		
		// adjust volume level up high
		private function scrubberUp(e:MouseEvent):void {
			_scrubber.stopDrag();
			var t:Number = (_scrubber.y - 95) * _model.streamLength / (_maxLength -7);
		}
		
		private function currentVol(e:Event):void{
			_volLevel = (!_muteState) ?_scrubber.y - _volumeBarYPosition:0;
			_volLevel = (_volLevel<0)?_volLevel * -1:_volLevel;
			
//			_highlight.graphics.clear();						
//			_highlight.graphics.beginFill(_volumdBarColor);
//			_highlight.graphics.drawRect(_volumeBarXPosition,_volumeBarYPosition,_volumBarWidth, 1 - _volLevel);
//			_highlight.graphics.endFill();	
			
			_volLevel = (_volLevel>_maxVolLevel)?100:_volLevel;
			if(_volLevel != _previousVolLevel)
			{
				_controller.setVolume(_volLevel/100);
				_previousVolLevel = _volLevel;
			}
		}
			
		private function implementClick(index:int):void {
			if(index == 0)
			{
				_volLevel = 0;
				_controller.setVolume(_volLevel);
			}
			else
			{
				_volLevel = index / 100;
				_controller.setVolume(_volLevel);
			}			
		}
		
		// toggle volume icon
		private function handleIconClick(e:MouseEvent):void {
			// validate mute state
			if (_muteState) {
				_volumeIcon.transform.colorTransform = new ColorTransform(1,1,1,1,0);
				_muteState = false;
				_controller.setVolume(_lastVolume/100);
				//implementClick(Math.round(_lastVolume*100));

			} else {
				_volumeIcon.transform.colorTransform = new ColorTransform(1,1,1,1,200);
				_muteState = true;
				_lastVolume = _model.volume;
				implementClick(0);
			}
		}
		
		// set volume level width
		public function setWidth(w:Number):void {
			_maxLength = w - 80;
			_maxVolLevel = (_maxLength<0)?_maxLength * -1:_maxLength;
			_background.graphics.clear();
			_background.graphics.beginFill(0xffffff);
			_background.graphics.drawRect(_volumeBarXPosition-13,_volumeBarYPosition+17,_backgroundWidth+2,_maxLength - 37);
			_background.graphics.endFill();			
			_background.graphics.beginFill(0x202020);
			_background.graphics.drawRect(_volumeBarXPosition-12,_volumeBarYPosition+16,_backgroundWidth,_maxLength - 35);
			_background.graphics.endFill();			
			
			_volumeBar.graphics.clear();						
			_volumeBar.graphics.beginFill(_volumdBarColor, .3);
			_volumeBar.graphics.drawRect(_volumeBarXPosition,_volumeBarYPosition,_volumBarWidth,_maxLength - 10);
			_volumeBar.graphics.endFill();			
			
//			_highlight.graphics.clear();						
//			_highlight.graphics.beginFill(_volumdBarColor);
//			_highlight.graphics.drawRect(_volumeBarXPosition,_volumeBarYPosition,_volumBarWidth,_maxLength + 5);
//			_highlight.graphics.endFill();	
			
		}		
	}
}
