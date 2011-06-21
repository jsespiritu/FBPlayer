package  view{
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.utils.ByteArray;
	import flash.ui.Mouse;
	import flash.utils.*;
	import flash.system.*;	import flash.external.ExternalInterface;
	import model.Model;
	import ui.CaptionButton;
	
	public class CaptionView extends MovieClip{

		private var _model:Model;
		private var _isVisible:Boolean;
		private var _message:String;
		private var _counter:uint = 0;
		private var _textBox:TextField;
		private var _availableVideoWidth:Number;
		private var _availableVideoHeight:Number
		private var _messageCount:Number = 0;
		
		public function CaptionView(model:Model) {
			// constructor code
			_model = model;
			
			if(_model.hasPlaylist && _model.playlistVisible){
				_availableVideoWidth = _model.width - (_model.playlistWidth + (!_model.isOverlay ? 6:0) + 20);
			}
			else if(_model.hasPlaylist && !_model.playlistVisible)
			{
				_availableVideoWidth = _model.width - (_model.playlistWidth + (!_model.isOverlay ? 6:0) + 20);
			}
			else
			{
				_availableVideoWidth = _model.width - ((!_model.isOverlay ? 6:0)) - 340;
				
			}
			_availableVideoHeight = _model.height - (_model.isOverlay ? 0:_model.controlbarHeight) - 6;			
			_model.addEventListener(_model.EVENT_RESIZE, resize)
			_model.addEventListener(_model.EVENT_PROGRESS, displayComment);
			_model.addEventListener(_model.EVENT_TOGGLE_CAPTION, toggleHandler);
			
			_textBox = new TextField();
			_textBox.embedFonts = true;
			var textFormat:TextFormat = new TextFormat();
			textFormat.font = new AkamaiArialBold().fontName;
			textFormat.size = _model.commentFontSize;
			textFormat.color = _model.fontColor;
			_textBox.defaultTextFormat = textFormat;
			_textBox.mouseEnabled = enabled;
			_textBox.selectable = enabled;
			
			_textBox.visible = false;
		}


		private function sendTime(e:Event):void{
			ExternalInterface.call("displayTime('" + _model.timeAsTimeCode + "')");
		}
		
		private function displayComment(e:Event):void{
			_counter++;

			if(_model.comment[_model.timeAsTimeCode] != undefined){
				_message = _model.comment[_model.timeAsTimeCode];					
				_textBox = generateTextField(_message);
				//_textBox.width = _availableVideoWidth - _model.commentWidth;
				_textBox.width = _model.commentWidth;
				_messageCount = _message.length;
				_textBox.x = _model.commentX - (_messageCount * 2);
				_textBox.y = _model.commentY + _availableVideoHeight - 99;
				this.addChild(_textBox);
				_counter = 0;
			}
			if(_counter > 8){
				_message = "";
				_textBox = generateTextField(_message);
				this.addChild(_textBox);
			}
			
		}
		
		private function generateTextField(text:String):TextField {
			_textBox.text = text;
			return _textBox;
		}
			
		private function toggleHandler(e:Event):void {
			_textBox.visible = !_textBox.visible;
		}
		
		public function resize(e:Event):void  {
			if(_model.hasPlaylist && _model.playlistVisible){
				_availableVideoWidth = _model.width - (_model.playlistWidth + (!_model.isOverlay ? 6:0) + 20);
			}
			else if(_model.hasPlaylist && !_model.playlistVisible)
			{
				_availableVideoWidth = _model.width - (_model.playlistWidth + (!_model.isOverlay ? 6:0) + 20);
			}
			else
			{
				_availableVideoWidth = _model.width - ((!_model.isOverlay ? 6:0)) - 340;
				
			}
			_availableVideoHeight = _model.height - (_model.isOverlay ? 0:_model.controlbarHeight) - 6;						
		}
	}
	
}
