package view{
	import controller.PlaylistController;
	import ui.*;
	import model.Model;
	import org.openvideoplayer.rss.*
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.text.*;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	import flash.display.*;
	import flash.events.*;
	
	public class OverlayPlaylistView extends MovieClip {
		private var _model:Model;
		private var _controller:PlaylistController;
		private var _background:MovieClip;
		private var _container:MovieClip;
		
		public function OverlayPlaylistView(model:Model):void {
			_model = model;
			
			_controller = new PlaylistController(_model, this);
			createChildren();
		}
		private function createChildren():void {
			_background = new MovieClip();
			addChild(_background);			
		}
	}
}
