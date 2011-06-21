package controller{

	import flash.events.*;
	import flash.display.*;
	import model.Model;

	/**
	 * Akamai Multi Player - controller working in conjunction with the VolumeControlView
	 */
	public class VolumeSliderController extends EventDispatcher {

		private var _model:Model;
		private var _view:MovieClip;

		public function VolumeSliderController(model:Model,view:MovieClip):void {
			_model = model;
			_view = view;
		}

		public function setVolume(level:Number):void {
			_model.volume = level;
		}
	}
}