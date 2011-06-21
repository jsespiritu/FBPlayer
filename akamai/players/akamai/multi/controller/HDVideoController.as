package  controller{
	
	import flash.display.MovieClip;
	import flash.net.NetConnection;
	import flash.media.Video;
	import com.akamai.hd.HDNetStream;
	import com.akamai.hd.HDEvent;
	import model.Model;
	import view.VideoView;

	public class HDVideoController extends MovieClip {

		public function HDVideoController(model:Model, view:VideoView):void {
			var _view = view;
			var nc:NetConnection = new NetConnection();
			nc.connect(null);
			var ns:HDNetStream = new HDNetStream(nc);
			ns.addEventListener(HDEvent.DEBUG,onDebug);
			var video:Video=new Video(640,360);
			//addChild(video);
			//video.attachNetStream(ns);
			video.attachNetStream(ns);
			ns.play("http://localhost/test/earth2.smil");
			//ns.play("http://localhost/videos/ad.flv");
		}
		
		private function onDebug(event:HDEvent):void{
			trace(event.data as String);
		}
	}
}
