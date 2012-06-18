package be.alfredo.fileformats.apng
{
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLStream;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	
	/**
	 * A streaming player/decoder for the APNG data format.
	 * This player loads an animated PNG
	 * 
	 * @author Frederick Jansen
	 */ 
	public class APNGPlayer extends Sprite
	{
		/**
		 * Stream of the APNG file
		 * @private
		 */ 
		private var stream:URLStream;
		
		/**
		 * Buffer of the file to be loaded
		 * @private
		 */
		private var apngBuffer:ByteArray = new ByteArray();
		
		/**
		 * Minimum size of the buffer before it's read
		 * @private
		 */
		private var bufferSize:uint = 1024 * 2;
		
		/**
		 * Whether to autoplay the animation or not
		 * @private
		 */ 
		private var autoplay:Boolean;
		
		/**
		 * Collection of all frames which can be looped through
		 * @private
		 */ 
		private var frames:Vector.<APNGFrame>;
		
		/**
		 * Decoder for the animated PNG
		 * @private
		 */ 
		private var apngDecoder:APNGDecoder;
		
		/**
		 * Timer to handle the animation of the frames
		 * @private
		 */ 
		private var playTimer:Timer;
		
		/**
		 * The current frame that's being shown
		 * @private
		 */ 
		private var currentFrame:uint = 0;
		
		/**
		 * The bitmap in which all frames are drawn
		 * @private
		 */ 
		private var bmp:Bitmap;
		
		/**
		 * @private
		 */ 
		private var _numFrames:uint;
		
		/**
		 * The amount of frames in the animation
		 */ 
		public function get numFrames():uint
		{
			return _numFrames;
		}
		
		public static var APNG_LOADED:String = "apng_loaded";
		
		/**
		 * Class constructor
		 * 
		 * @param	autoplay	Whether the animation should start playing 
		 * 			automatically after loading.
		 */ 
		public function APNGPlayer( autoplay:Boolean = true )
		{
			stream = new URLStream();
			stream.addEventListener( ProgressEvent.PROGRESS, readBuffer );
			stream.addEventListener( IOErrorEvent.IO_ERROR, ioErrorHandler );
			stream.addEventListener( Event.COMPLETE, completeHandler );
			
			playTimer = new Timer(75);
			playTimer.addEventListener( TimerEvent.TIMER, updateFrame );
			
			this.autoplay = autoplay;
		}
		
		/**
		 * Start loading the animated PNG
		 * 
		 * @param	url	Location of the APNG file
		 */ 
		public function load( url:URLRequest ):void
		{
			stream.load( url );
		}
		
		/**
		 * Play the animation
		 */ 
		public function play():void
		{
			if( !playTimer.running )
			{
				playTimer.start();				
			}
		}
		
		/**
		 * Stop/pause the animation
		 */ 
		public function stop():void
		{
			if( playTimer.running )
			{
				playTimer.stop();				
			}
		}
		
		/**
		 * Play the animation from a specified frame
		 * 
		 * @param	frameNumber	The frame the animation has to start from, 
		 * 			should be a value between 0 and numFrames - 1
		 */ 
		public function gotoAndPlay( frameNumber:uint ):void
		{
			if( frameNumber < apngDecoder.numFrames )
			{
				currentFrame = frameNumber;
				if( !playTimer.running )
				{
					playTimer.start();
				}
			}
			else
			{
				throw new Error( "Frame number should be between 0 and "+ (apngDecoder.numFrames - 1) );
			}
		}
		
		/**
		 * Display a specific frame and stop the animation
		 * 
		 * @param	frameNumber	The frame you want to display, should be 
		 * 			a value between 0 and numFrames - 1
		 */ 		
		public function gotoAndStop( frameNumber:uint ):void
		{
			if( frameNumber < apngDecoder.numFrames )
			{
				currentFrame = frameNumber;
				if( playTimer.running )
				{
					playTimer.stop();
				}
				updateFrame(null);
			}
			else
			{
				throw new Error( "Frame number should be between 0 and "+ (apngDecoder.numFrames - 1) );
			}
		}
		
		/**
		 * Timer handler which loops through the frames
		 * 
		 * @param	event	Timer event
		 */ 
		private function updateFrame(event:TimerEvent):void
		{
			bmp.bitmapData = frames[currentFrame].images[0];
			// TODO: Delay is slightly larger than natively in the browser
			playTimer.delay = frames[currentFrame].delay;
			
			if( currentFrame == apngDecoder.numFrames - 1 )
			{
				currentFrame = 0;
			}
			else
			{
				currentFrame++;
			}
		}
		
		/**
		 * Called after the file has been downloaded
		 * 
		 * @param	event	Complete event
		 */ 
		private function completeHandler( event:Event ):void
		{
			stream.readBytes( apngBuffer, apngBuffer.length, stream.bytesAvailable );
			
			stream.removeEventListener( ProgressEvent.PROGRESS, readBuffer );
			stream.removeEventListener( IOErrorEvent.IO_ERROR, ioErrorHandler );
			stream.removeEventListener( Event.COMPLETE, completeHandler );
			
			trace("complete event");
			
			// Decode the remaining buffer while the end of the file hasn't been reached
			while( !apngDecoder.eof )
			{
				trace("not eof");
				if( !APNGDecoder.DECODING_FRAME )
				{
					trace("still decoding");
					apngDecoder.parseChunks( apngBuffer );
				}
			}
		}
		
		/**
		 * To mimic browser behaviour, show the latest decoded frame 
		 * from the stream
		 * 
		 * @param	event	Frame decoded event
		 */ 
		protected function frameDecodedHandler( event:Event ):void
		{
			frames = apngDecoder.frames;
			
			bmp.bitmapData = frames[currentFrame].images[0];
			currentFrame++;
		}
		
		/**
		 * Called after the file has been decoded
		 * 
		 * @param	event	Animation Loaded event
		 */ 
		private function animationLoadedHandler(event:Event):void
		{
			currentFrame = 0;
			
			apngDecoder.removeEventListener( APNGDecoder.ANIMATION_LOADED, animationLoadedHandler );
			apngDecoder.removeEventListener( APNGDecoder.FRAME_DECODED, animationLoadedHandler );
			
			if( autoplay )
			{
				playTimer.start();
			}
			_numFrames = apngDecoder.numFrames;
			dispatchEvent( new Event( APNG_LOADED ) );
		}
		
		/**
		 * Url loader error handler
		 * 
		 * @param	event	IO error event
		 */ 
		private function ioErrorHandler( event:IOErrorEvent ):void
		{
			dispatchEvent( event );
		}
		
		/**
		 * Handle the incoming stream
		 * 
		 * @param	event	ProgressEvent
		 */ 
		protected function readBuffer( event:ProgressEvent ):void
		{
			if( stream.bytesAvailable > bufferSize )
			{
				// TODO: Check how the apngBuffer contents is affected when this event is triggered
				stream.readBytes( apngBuffer, apngBuffer.length, stream.bytesAvailable );
				if( apngDecoder == null )
				{
					bmp = new Bitmap( null );
					addChild( bmp );
					
					apngDecoder = new APNGDecoder( apngBuffer );
					apngDecoder.addEventListener( APNGDecoder.FRAME_DECODED, frameDecodedHandler );
					apngDecoder.addEventListener( APNGDecoder.ANIMATION_LOADED, animationLoadedHandler );
					apngDecoder.startDecoding();
				}
				else
				{
					if( !APNGDecoder.DECODING_FRAME )
					{
						apngDecoder.parseChunks( apngBuffer );
					}
				}
			}
		}
	}
}