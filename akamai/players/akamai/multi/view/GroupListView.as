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
	import flash.external.ExternalInterface;
	
	public class GroupListView extends MovieClip{
		private var _model:Model;
		private var _background:MovieClip;
		private var _isVisible:Boolean;
		private var _smalButton:SmallButton;
		private var _showUserList:SmallButton;
		private var _showSeriesList:SmallButton;

		public function GroupListView(model:Model) {
			// constructor code
			_model = model;
			_model.addEventListener(_model.EVENT_RESIZE, resize);
			_model.addEventListener(_model.EVENT_TOGGLE_GROUPLIST, toggleGroupListHandler);
			_model.addEventListener(_model.EVENT_SHOW_GROUPLIST_SELECTION, showGroupListHandler);
			_model.addEventListener(_model.EVENT_HIDE_GROUPLIST_SELECTION, hideGroupListHandler);
			
			this.createChildren();			
		}
		
		private function createChildren():void{
			
			_background = new MovieClip();
			addChild(_background);
			
			_showUserList = generateButton("userlist","Show User List");
			addChild(_showUserList);
			_showSeriesList = this.generateButton("serieslist","Show Series List");
			addChild(_showSeriesList);
					
			this.visible = false;
			_isVisible = false;
		}		
		
		private function showGroupListHandler(e:Event):void {
			if (_isVisible) {
				this.visible = true;
			}
		}
		private function hideGroupListHandler(e:Event):void {
				this.visible = false;
		}
		private function toggleGroupListHandler(e:Event):void {
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
			button.addEventListener(MouseEvent.CLICK, viewList);
			var buttonName:TextField = new TextField();
			buttonName.embedFonts = true;
			var textFormat:TextFormat = new TextFormat();
			textFormat.font = new AkamaiArialBold().fontName;
			textFormat.size = 11;
			textFormat.color = _model.fontColor
			buttonName.defaultTextFormat = textFormat;
			buttonName.text = desc;
			buttonName.width = 150;
			buttonName.height = 20;
			buttonName.x = 8;
			buttonName.y = -7;
			button.addChild(buttonName);
			return button;
		}
		
		private function viewList(evt:Event):void{
			switch(evt.currentTarget.name){
				case "userlist":
					ExternalInterface.call("showUserList()");
				break;
				case "serieslist":
					ExternalInterface.call("showSeriesList()");
				break;
			}
			this.visible = false;
			_isVisible = false;
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
			var _availableVideoHeight:Number = _model.height - (_model.isOverlay ? 0:_model.controlbarHeight) - 6;
			
			
			if(_model.isOverlay){
				//var xOBackground:Number = (_model.hasPlaylist)?(_model.playlistVisible)?220:-80:10;
				var xOBackground:Number = (_model.hasPlaylist)?(_model.playlistVisible)?220:-100:-128;
				var xOUserList:Number = (_model.hasPlaylist)?(_model.playlistVisible)?200:-110:-137;
				var xOSeriesList:Number = (_model.hasPlaylist)?(_model.playlistVisible)?200:-110:-137;
				this.graphics.clear();
				this.graphics.beginFill(_model.controlbarOverlayColor, .9);
				//this.graphics.drawRect(_availableVideoWidth - xOBackground, 3 + _availableVideoHeight - 153,150, 83);
				this.graphics.drawRect(_availableVideoWidth - xOBackground, _availableVideoHeight - 90,115, 50);
				this.graphics.endFill();
				_showUserList.x = 3 + _availableVideoWidth - xOUserList;
				_showUserList.y = _availableVideoHeight - 55;
				_showSeriesList.x = 3 + _availableVideoWidth - xOSeriesList;
				_showSeriesList.y =_availableVideoHeight - 75;
			}
			else{
				var xBackground:Number = (_model.hasPlaylist)?(_model.playlistVisible)?420:-40:0;
				var xUserList:Number = (_model.hasPlaylist)?(_model.playlistVisible)?400:-60:-20;
				var xSeriesList:Number = (_model.hasPlaylist)?(_model.playlistVisible)?400:-60:-20;
				this.graphics.clear();
				this.graphics.beginFill(_model.controlbarOverlayColor, .9);
				this.graphics.drawRect(_availableVideoWidth - xBackground, 3 + _availableVideoHeight - 85,150, 83);
				this.graphics.endFill();
				_showUserList.x = 3 + _availableVideoWidth - xUserList;
				_showUserList.y = 3 + _availableVideoHeight - 65;
				_showSeriesList.x = 3 + _availableVideoWidth - xSeriesList;
				_showSeriesList.y = 37 + _availableVideoHeight - 65;		
			}
		}
	}
	
}
