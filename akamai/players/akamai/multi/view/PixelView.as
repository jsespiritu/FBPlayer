/*
	author:	jerwin s. espiritu
*/

package view {
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.utils.ByteArray;
	import flash.ui.Mouse;
	import flash.utils.*;
	import flash.system.*;
	import model.Model;
	import view.*;
	import ui.*;
	import flash.text.engine.ContentElement;
	import flash.net.URLLoader;
	import flash.globalization.LocaleID;
	import flash.net.URLRequest;
	
	public class PixelView extends MovieClip{
		private var _model:Model;
		private var _background:MovieClip;
		private var _isVisible:Boolean;
		private var _currentPixel:String = "360p";
		private var _pixelXML:XML;
		private var _240p:String;
		private var _360p:String;
		private var _480p:String;
		private var _pixelXMLLoader:URLLoader;
		private var _smalButton:SmallButton;
		private var _radioButton240p:SmallButton;
		private var _radioButton360p:SmallButton;
		private var _radioButton480p:SmallButton;
		private var _radioButtonAutoSwitch:SmallButton;
		private var _previousPixelSetting:String;

		public function PixelView(model:Model):void {
			// constructor code
			_model = model;
			_model.addEventListener(_model.EVENT_PROGRESS, getCurrentPixelSetting);
			_model.addEventListener(_model.EVENT_RESIZE, resize);
			_model.addEventListener(_model.EVENT_TOGGLE_PIXEL, togglePixelHandler);
			_model.addEventListener(_model.EVENT_SHOW_PIXEL_SELECTION, showPixelHandler);
			_model.addEventListener(_model.EVENT_HIDE_PIXEL_SELECTION, hidePixelHandler);
			
			_pixelXMLLoader = new URLLoader();
			_pixelXMLLoader.addEventListener(Event.COMPLETE, processXML);						
			this.createChildren();			
		}
		private function createChildren():void{
			
			_background = new MovieClip();
			addChild(_background);
			
			_radioButton240p = generateButton("240p","240p");
			addChild(_radioButton240p);
			_radioButton360p = this.generateButton("360p","360p");
			addChild(_radioButton360p);
			_radioButton480p = this.generateButton("480p","480p");
			addChild(_radioButton480p);
			_radioButtonAutoSwitch = this.generateButton("auto", "Auto");
			addChild(_radioButtonAutoSwitch);
					
			this.visible = false;
			_isVisible = false;
		}		
		
		private function getCurrentPixelSetting(e:Event){
			_model.currentPixelSetting = _currentPixel;
			if(_model.currentPixelSetting != _previousPixelSetting)
			{
				//_currentPixelSetting = _currentPixel;
				_previousPixelSetting = _currentPixel;
			}
			
		}
		private function showPixelHandler(e:Event):void {
			if (_isVisible) {
				this.visible = true;
			}
		}
		private function hidePixelHandler(e:Event):void {
				this.visible = false;
		}
		private function togglePixelHandler(e:Event):void {
			this.visible = !this.visible;
			_isVisible = this.visible;
		}
		
		private function generateButton(name:String, desc:String):SmallButton{
			var transform:ColorTransform = new ColorTransform();
			transform.color = _model.themeColor;
			var button:SmallButton = new SmallButton();
			button.name = name;
			button.addEventListener(MouseEvent.MOUSE_OVER,genericMouseOver);
			button.addEventListener(MouseEvent.MOUSE_OUT,genericMouseOut);			
			button.addEventListener(MouseEvent.MOUSE_DOWN,genericMouseDown);
			button.addEventListener(MouseEvent.MOUSE_UP,genericMouseUp);
			button.addEventListener(MouseEvent.CLICK, playRequest);
			var buttonName:TextField = new TextField();
			buttonName.embedFonts = true;
			var textFormat:TextFormat = new TextFormat();
			textFormat.font = new AkamaiArialBold().fontName;
			textFormat.size = 11;
			textFormat.color = _model.fontColor
			buttonName.defaultTextFormat = textFormat;
			buttonName.text = desc;
			buttonName.width = name=="auto"?150:30;
			buttonName.height = 20;
			buttonName.x = 8;
			buttonName.y = -7;
			button.addChild(buttonName);
			return button;
		}
		
		private function playRequest(evt:Event):void{
			var _currentPlaying:String = _model.src;
//			var _fileExt:String = _currentPlaying.substr(-4,4);
//			var _fileSwitch:String = _currentPlaying.substr(0,-7);
			var _fileExt:String = _currentPlaying.substr(-9,9);
			var _fileSwitch:String = _currentPlaying.substr(0,-12);
			
			_currentPlaying = _model.src;
			switch(evt.currentTarget.name){
				case "240p":
					_currentPixel = "240p";
					_model.src = _fileSwitch + _model.VIDEO_240P + _fileExt;
				break;
				case "360p":
					_currentPixel = "360p";
					_model.src = _fileSwitch + _model.VIDEO_360P + _fileExt;
				break;
				case "480p":
					_currentPixel = "480p";
					_model.src = _fileSwitch + _model.VIDEO_480P + _fileExt;
				break;
				case "auto":
					_currentPixel = "Auto";
				break;
			}
			trace(_model.src);
			this.visible = false;
			_isVisible = false;
			_model.playStart();
		}
		
		private function genericMouseDown(e:MouseEvent):void {
			e.currentTarget.x += 1;
			e.currentTarget.y += 1;
		}
		private function genericMouseUp(e:MouseEvent):void {
			e.currentTarget.x -= 1;
			e.currentTarget.y -= 1;
		}
		private function genericMouseOver(e:MouseEvent):void {
			e.currentTarget.highlight.alpha = 1;
		}
		private function genericMouseOut(e:MouseEvent):void {
			e.currentTarget.highlight.alpha = 0;
		}
		public function resize(e:Event):void  {
			//draw background
			var _availableVideoWidth:Number;
			if(_model.hasPlaylist && _model.playlistVisible){
				_availableVideoWidth = _model.width - (_model.playlistWidth + (!_model.isOverlay ? 6:0) + 20);
			}
			else if(_model.hasPlaylist && !_model.playlistVisible)
			{
				//_availableVideoWidth = _model.width - (_model.playlistWidth + (!_model.isOverlay ? 6:0) - 257);
				_availableVideoWidth = _model.width - (_model.playlistWidth + (!_model.isOverlay ? 6:0) + 20);
			}
			else
			{
				_availableVideoWidth = _model.width - ((!_model.isOverlay ? 6:0)) - 340;				
			}
			var _availableVideoHeight:Number = _model.height - (_model.isOverlay ? _model.controlbarHeight / 2:_model.controlbarHeight) - 6;
			
			//trace("===============  " + _model.hasPlaylist);
			if(_model.isOverlay){
				var xOBackground:Number = (_model.hasPlaylist)?(_model.playlistVisible)?40:-100:-130;
				
/*				var xO480:Number = (_model.hasPlaylist)?(_model.playlistVisible)?40:-180:-170;
				var xO360:Number = (_model.hasPlaylist)?(_model.playlistVisible)?120:-100:-90;
				var xO240:Number = (_model.hasPlaylist)?(_model.playlistVisible)?200:-20:-10;
				var xOAuto:Number = (_model.hasPlaylist)?(_model.playlistVisible)?200:-20:-10;
*/				
				var xO240:Number = (_model.hasPlaylist)?(_model.playlistVisible)?140:-110:-140;
				var xO360:Number = (_model.hasPlaylist)?(_model.playlistVisible)?140:-110:-140;
				var xO480:Number = (_model.hasPlaylist)?(_model.playlistVisible)?140:-110:-140;
				var xOAuto:Number = (_model.hasPlaylist)?(_model.playlistVisible)?140:-110:-140;
				this.graphics.clear();
				this.graphics.beginFill(_model.controlbarOverlayColor, .9);
				//this.graphics.drawRect(_availableVideoWidth - xOBackground, 3 + _availableVideoHeight - 118,236, 83);
				this.graphics.drawRect(_availableVideoWidth - xOBackground, 30 + _availableVideoHeight - 118,56, 83);
				this.graphics.endFill();
				_radioButton240p.x = 3 + _availableVideoWidth - xO240;
				_radioButton240p.y = 24 + _availableVideoHeight - 100;
				_radioButton360p.x = 3 + _availableVideoWidth - xO360;
				_radioButton360p.y = 44 + _availableVideoHeight - 100;
				_radioButton480p.x = 3 + _availableVideoWidth - xO480;
				_radioButton480p.y = 64 + _availableVideoHeight - 100;
				_radioButtonAutoSwitch.x = 3 + _availableVideoWidth - xOAuto;
				_radioButtonAutoSwitch.y = 84 + _availableVideoHeight - 100;
			}
			else{
				var xBackground:Number = (_model.hasPlaylist)?(_model.playlistVisible)?420:0:0;
				var x480:Number = (_model.hasPlaylist)?(_model.playlistVisible)?240:-180:-180;
				var x360:Number = (_model.hasPlaylist)?(_model.playlistVisible)?320:-100:-100;
				var x240:Number = (_model.hasPlaylist)?(_model.playlistVisible)?400:-20:-20;
				var xAuto:Number = (_model.hasPlaylist)?(_model.playlistVisible)?400:-20:-20;
				this.graphics.clear();
				this.graphics.beginFill(_model.controlbarOverlayColor, .9);
				this.graphics.drawRect(_availableVideoWidth - xBackground, 3 + _availableVideoHeight - 85,236, 83);
				this.graphics.endFill();
				_radioButton480p.x = 3 + _availableVideoWidth - x480;
				_radioButton480p.y = 3 + _availableVideoHeight - 65;
				_radioButton360p.x = 3 + _availableVideoWidth - x360;
				_radioButton360p.y = 3 + _availableVideoHeight - 65;
				_radioButton240p.x = 3 + _availableVideoWidth - x240;
				_radioButton240p.y = 3 + _availableVideoHeight - 65;
				_radioButtonAutoSwitch.x = 3 + _availableVideoWidth - xAuto;
				_radioButtonAutoSwitch.y = 37 + _availableVideoHeight - 65;		
			}
		}
		
		private function processXML(e:Event):void{
			_pixelXML = new XML(e.target.data);
			_240p = _pixelXML.pixel[0];
			_360p = _pixelXML.pixel[1];
			_480p = _pixelXML.pixel[2];
		}
		
		
	}
	
}
