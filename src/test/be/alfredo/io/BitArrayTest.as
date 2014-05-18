package be.alfredo.io
{

	import org.hamcrest.assertThat;
	import org.hamcrest.object.equalTo;

	public class BitArrayTest
	{

		private var bitArray:BitArray;

		public function BitArrayTest()
		{
		}

		[Before]
		public function setUp():void
		{
			bitArray = new BitArray();
			bitArray.writeUnsignedInt( 0x89504E47 );
			bitArray.writeUnsignedInt( 0x0D0A1A0A );
		}

		[After]
		public function tearDown():void
		{
			bitArray = null;
		}

		[Test]
		public function testReadUnary():void
		{

		}

		[Test]
		public function testReadSignedBits():void
		{

		}

		[Test]
		public function testPosition():void
		{

		}

		[Test]
		public function testReadSignedRice():void
		{

		}

		[Test]
		public function testReadUnsignedUTF8():void
		{

		}

		[Test]
		public function testBitPosition():void
		{

		}

		[Test]
		public function testByteAlignRight():void
		{
			bitArray.position = 0;
			bitArray.bitPosition = 5;
			assertThat( bitArray.position, equalTo( 0 ) );
			bitArray.byteAlignRight();
			assertThat( bitArray.position, equalTo( 1 ) );
		}

		[Test]
		public function testReadUnsignedBits():void
		{
			bitArray.position = 0;
			assertThat( bitArray.readUnsignedBits( 5 ), equalTo( 0x11 ) );
			assertThat( bitArray.readUnsignedBits( 3 ), equalTo( 0x01 ) );
			assertThat( bitArray.readUnsignedBits( 12 ), equalTo( 0x504 ) );
			assertThat( bitArray.readUnsignedBits( 5 ), equalTo( 0x1C ) );
			bitArray.position = 7;
			assertThat( bitArray.readUnsignedBits( 8 ), equalTo( 0x0A ) );
		}

		[Test]
		public function testReadBit():void
		{
			bitArray.position = 0;
			assertThat( bitArray.readBit(), equalTo( 1 ) );
			assertThat( bitArray.readBit(), equalTo( 0 ) );
			assertThat( bitArray.readBit(), equalTo( 0 ) );
			assertThat( bitArray.readBit(), equalTo( 0 ) );
			assertThat( bitArray.readBit(), equalTo( 1 ) );
			assertThat( bitArray.readBit(), equalTo( 0 ) );
			assertThat( bitArray.readBit(), equalTo( 0 ) );
			assertThat( bitArray.readBit(), equalTo( 1 ) );
			assertThat( bitArray.readBit(), equalTo( 0 ) );
			assertThat( bitArray.readBit(), equalTo( 1 ) );
			assertThat( bitArray.readBit(), equalTo( 0 ) );
			assertThat( bitArray.readBit(), equalTo( 1 ) );
		}
	}
}
