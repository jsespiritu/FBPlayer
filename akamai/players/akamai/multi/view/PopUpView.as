package  view{
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.utils.ByteArray;
	import flash.ui.Mouse;
	import flash.utils.*;
	import flash.system.*;
	import flash.external.ExternalInterface;
	import model.Model;
	import view.*;
	
	public class PopUpView extends MovieClip{
		private var _model:Model;

		public function PopUpView(model:Model):void {
			// constructor code
			_model = model;
			//_model.addEventListener(_model.EVENT_RESIZE, resize);
			_model.addEventListener(_model.EVENT_CLICK_POPUP, popUpHandler);
		}
		
		private function popUpHandler(e:Event):void{
			var videoContent:String = _model.src;
			ExternalInterface.call("openVideo('" + videoContent + "')");
		}

	}
	
}
