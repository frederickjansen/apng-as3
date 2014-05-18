package be.alfredo.fileformats.apng
{
	/**
	 * An APNG frame, consisting of the Frame Control Chunk, images and 
	 * delay before showing the next image.
	 * 
	 * @author Frederick Jansen
	 */ 
	internal class APNGFrame
	{
		public var frameControlChunk:FrameControlChunk;
		public var delay:uint;
		public var images:Array;
		
		public function APNGFrame( frameControlChunk:FrameControlChunk, delay:uint )
		{
			this.frameControlChunk = frameControlChunk;
			this.delay = delay;
			images = new Array();
		}
	}
}