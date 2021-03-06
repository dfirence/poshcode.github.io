<#

After running this, it adds a static [sat] class to PowerShell:

[sat]::add_Whatever($a, $b)
# does saturated addition

[sat]::iWhatever($a)
[sat]::uWhatever($a)
# converts $a into i/uWhatever using saturated conversions

Floating point in the range are converted to integers using C style truncation rather than PowerShell's round to nearest.

#>

Add-Type -ReferencedAssemblies System.Numerics -TypeDefinition @'
public static class sat {
	public static sbyte add_i8(sbyte a, sbyte b) {unchecked{
		int temp = a + b;
		if (temp > sbyte.MaxValue) temp = sbyte.MaxValue;
		if (temp < sbyte.MinValue) temp = sbyte.MinValue;
		return (sbyte)temp;
	}}
	public static byte add_u8(byte a, byte b) {unchecked{
		uint temp = (uint)(a + b);
		if (temp > byte.MaxValue) temp = byte.MaxValue;
		return (byte)temp;
	}}
	public static short add_i16(short a, short b) {unchecked{
		int temp = a + b;
		if (temp > short.MaxValue) temp = short.MaxValue;
		if (temp < short.MinValue) temp = short.MinValue;
		return (short)temp;
	}}
	public static ushort add_u16(ushort a, ushort b) {unchecked{
		uint temp = (uint)(a + b);
		if (temp > ushort.MaxValue) temp = ushort.MaxValue;
		return (ushort)temp;
	}}
	public static int add_i32(int a, int b) {unchecked{
		long temp = a + b;
		if (temp > int.MaxValue) temp = int.MaxValue;
		if (temp < int.MinValue) temp = int.MinValue;
		return (int)temp;
	}}
	public static uint add_u32(uint a, uint b) {unchecked{
		ulong temp = a + b;
		if (temp > uint.MaxValue) temp = uint.MaxValue;
		return (uint)temp;
	}}
	public static long add_i64(long a, long b) {unchecked{
		ulong ret = (ulong)a + (ulong)b;
		ulong ov = ((long)ret < 0) ? (ulong)long.MaxValue : (ulong)long.MinValue;
		if ((long)(((ulong)a ^ ret) & ((ulong)b ^ ret)) < 0)
			ret = ov;
		return (long)ret;
	}}
	public static ulong add_u64(ulong a, ulong b) {unchecked{
		return a + b < a ? ulong.MaxValue : a + b;
	}}

	public static sbyte i8(sbyte value) { return value; }
	public static sbyte i8(byte value) {unchecked{ return (sbyte)value >= 0 ? (sbyte)value : sbyte.MaxValue; }}
	public static sbyte i8(short value) {unchecked{ return value <= sbyte.MinValue ? sbyte.MinValue : value >= sbyte.MaxValue ? sbyte.MaxValue : (sbyte)value; }}
	public static sbyte i8(ushort value) {unchecked{ return value <= (byte)sbyte.MaxValue ? (sbyte)value : sbyte.MaxValue; }}
	public static sbyte i8(int value) {unchecked{ return value <= sbyte.MinValue ? sbyte.MinValue : value >= sbyte.MaxValue ? sbyte.MaxValue : (sbyte)value; }}
	public static sbyte i8(uint value) {unchecked{ return value <= sbyte.MaxValue ? (sbyte)value : sbyte.MaxValue; }}
	public static sbyte i8(long value) {unchecked{ return value <= sbyte.MinValue ? sbyte.MinValue : value >= sbyte.MaxValue ? sbyte.MaxValue : (sbyte)value; }}
	public static sbyte i8(ulong value) {unchecked{ return value <= (byte)sbyte.MaxValue ? (sbyte)value : sbyte.MaxValue; }}
	public static sbyte i8(float value) { return value <= sbyte.MinValue ? sbyte.MinValue : value >= sbyte.MaxValue ? sbyte.MaxValue : checked((sbyte)value); }
	public static sbyte i8(double value) { return value <= sbyte.MinValue ? sbyte.MinValue : value >= sbyte.MaxValue ? sbyte.MaxValue : checked((sbyte)value); }
	public static sbyte i8(decimal value) { return value <= sbyte.MinValue ? sbyte.MinValue : value >= sbyte.MaxValue ? sbyte.MaxValue : checked((sbyte)value); }
	public static sbyte i8(System.Numerics.BigInteger value) { return value <= (long)sbyte.MinValue ? sbyte.MinValue : value >= (long)sbyte.MaxValue ? sbyte.MaxValue : (sbyte)value; }

	public static byte u8(sbyte value) { return value >= 0 ? (byte)value : (byte)0; }
	public static byte u8(byte value) { return value; }
	public static byte u8(short value) {unchecked{ return value <= 0 ? (byte)0 : value >= byte.MaxValue ? byte.MaxValue : (byte)value; }}
	public static byte u8(ushort value) {unchecked{ return value <= byte.MaxValue ? (byte)value : byte.MaxValue; }}
	public static byte u8(int value) {unchecked{ return value <= 0 ? (byte)0 : value >= byte.MaxValue ? byte.MaxValue : (byte)value; }}
	public static byte u8(uint value) {unchecked{ return value <= byte.MaxValue ? (byte)value : byte.MaxValue; }}
	public static byte u8(long value) {unchecked{ return value <= 0 ? (byte)0 : value >= byte.MaxValue ? byte.MaxValue : (byte)value; }}
	public static byte u8(ulong value) {unchecked{ return value <= byte.MaxValue ? (byte)value : byte.MaxValue; }}
	public static byte u8(float value) { return value <= 0 ? (byte)0 : value >= byte.MaxValue ? byte.MaxValue : checked((byte)value); }
	public static byte u8(double value) { return value <= 0 ? (byte)0 : value >= byte.MaxValue ? byte.MaxValue : checked((byte)value); }
	public static byte u8(decimal value) { return value <= 0 ? (byte)0 : value >= byte.MaxValue ? byte.MaxValue : checked((byte)value); }
	public static byte u8(System.Numerics.BigInteger value) { return value.Sign <= 0 ? (byte)0 : value >= byte.MaxValue ? byte.MaxValue : (byte)value; }

	public static short i16(sbyte value) { return value; }
	public static short i16(byte value) { return value; }
	public static short i16(short value) { return value; }
	public static short i16(ushort value) {unchecked{ return (short)value >= 0 ? (short)value : short.MaxValue; }}
	public static short i16(int value) {unchecked{ return value <= short.MinValue ? short.MinValue : value >= short.MaxValue ? short.MaxValue : (short)value; }}
	public static short i16(uint value) {unchecked{ return value <= (ushort)short.MaxValue ? (short)value : short.MaxValue; }}
	public static short i16(long value) {unchecked{ return value <= short.MinValue ? short.MinValue : value >= short.MaxValue ? short.MaxValue : (short)value; }}
	public static short i16(ulong value) {unchecked{ return value <= (ushort)short.MaxValue ? (short)value : short.MaxValue; }}
	public static short i16(float value) { return value <= short.MinValue ? short.MinValue : value >= short.MaxValue ? short.MaxValue : checked((short)value); }
	public static short i16(double value) { return value <= short.MinValue ? short.MinValue : value >= short.MaxValue ? short.MaxValue : checked((short)value); }
	public static short i16(decimal value) { return value <= short.MinValue ? short.MinValue : value >= short.MaxValue ? short.MaxValue : checked((short)value); }
	public static short i16(System.Numerics.BigInteger value) { return value <= (long)short.MinValue ? short.MinValue : value >= (long)short.MaxValue ? short.MaxValue : (short)value; }

	public static ushort u16(sbyte value) {unchecked{ return value >= 0 ? (ushort)value : (ushort)0; }}
	public static ushort u16(byte value) { return value; }
	public static ushort u16(short value) {unchecked{ return value >= 0 ? (ushort)value : (ushort)0; }}
	public static ushort u16(ushort value) { return value; }
	public static ushort u16(int value) {unchecked{ return value <= 0 ? (ushort)0 : value >= ushort.MaxValue ? ushort.MaxValue : (ushort)value; }}
	public static ushort u16(uint value) {unchecked{ return value <= ushort.MaxValue ? (ushort)value : ushort.MaxValue; }}
	public static ushort u16(long value) {unchecked{ return value <= 0 ? (ushort)0 : value >= ushort.MaxValue ? ushort.MaxValue : (ushort)value; }}
	public static ushort u16(ulong value) {unchecked{ return value <= ushort.MaxValue ? (ushort)value : ushort.MaxValue; }}
	public static ushort u16(float value) { return value <= 0 ? (ushort)0 : value >= ushort.MaxValue ? ushort.MaxValue : checked((ushort)value); }
	public static ushort u16(double value) { return value <= 0 ? (ushort)0 : value >= ushort.MaxValue ? ushort.MaxValue : checked((ushort)value); }
	public static ushort u16(decimal value) { return value <= 0 ? (ushort)0 : value >= ushort.MaxValue ? ushort.MaxValue : checked((ushort)value); }
	public static ushort u16(System.Numerics.BigInteger value) { return value.Sign <= 0 ? (ushort)0 : value >= (long)ushort.MaxValue ? ushort.MaxValue : (ushort)value; }

	public static int i32(sbyte value) { return value; }
	public static int i32(byte value) { return value; }
	public static int i32(short value) { return value; }
	public static int i32(ushort value) { return value; }
	public static int i32(int value) { return value; }
	public static int i32(uint value) {unchecked{ return (int)value >= 0 ? (int)value : int.MaxValue; }}
	public static int i32(long value) {unchecked{ return value <= int.MinValue ? int.MinValue : value >= int.MaxValue ? int.MaxValue : (int)value; }}
	public static int i32(ulong value) {unchecked{ return value <= (uint)int.MaxValue ? (int)value : int.MaxValue; }}
	public static int i32(float value) { return value <= int.MinValue ? int.MinValue : value >= -(float)int.MinValue ? int.MaxValue : checked((int)value); }
	public static int i32(double value) { return value <= int.MinValue ? int.MinValue : value >= int.MaxValue ? int.MaxValue : checked((int)value); }
	public static int i32(decimal value) { return value <= int.MinValue ? int.MinValue : value >= int.MaxValue ? int.MaxValue : checked((int)value); }
	public static int i32(System.Numerics.BigInteger value) { return value <= (long)int.MinValue ? int.MinValue : value >= (long)int.MaxValue ? int.MaxValue : (int)value; }

	public static uint u32(sbyte value) {unchecked{ return value >= 0 ? (byte)value : 0U; }}
	public static uint u32(byte value) { return value; }
	public static uint u32(short value) {unchecked{ return value >= 0 ? (ushort)value : 0U; }}
	public static uint u32(ushort value) { return value; }
	public static uint u32(int value) {unchecked{ return value >= 0 ? (uint)value : 0U; }}
	public static uint u32(uint value) { return value; }
	public static uint u32(long value) {unchecked{ return value <= 0 ? 0U : value >= uint.MaxValue ? uint.MaxValue : (uint)value; }}
	public static uint u32(ulong value) {unchecked{ return value <= uint.MaxValue ? (uint)value : uint.MaxValue; }}
	public static uint u32(float value) { return value <= 0 ? 0U : value >= 4294967296.0f ? uint.MaxValue : checked((uint)value); }
	public static uint u32(double value) { return value <= 0 ? 0U : value >= uint.MaxValue ? uint.MaxValue : checked((uint)value); }
	public static uint u32(decimal value) { return value <= 0 ? 0U : value >= uint.MaxValue ? uint.MaxValue : checked((uint)value); }
	public static uint u32(System.Numerics.BigInteger value) { return value.Sign <= 0 ? 0U : value >= (long)uint.MaxValue ? uint.MaxValue : (uint)value; }

	public static long i64(sbyte value) { return value; }
	public static long i64(byte value) { return value; }
	public static long i64(short value) { return value; }
	public static long i64(ushort value) { return value; }
	public static long i64(int value) { return value; }
	public static long i64(uint value) { return value; }
	public static long i64(long value) { return value; }
	public static long i64(ulong value) {unchecked{ return (long)value >= 0 ? (long)value : long.MaxValue; }}
	public static long i64(float value) { return value <= long.MinValue ? long.MinValue : value >= -(float)long.MinValue ? long.MaxValue : checked((int)value); }
	public static long i64(double value) { return value <= long.MinValue ? long.MinValue : value >= -(double)long.MinValue ? long.MaxValue : checked((int)value); }
	public static long i64(decimal value) {unchecked{ return value >= long.MaxValue ? long.MaxValue : value <= long.MinValue ? long.MinValue : (long)value; }}
	public static long i64(System.Numerics.BigInteger value) { return value >= long.MaxValue ? long.MaxValue : value <= long.MinValue ? long.MinValue : (long)value; }

	public static ulong u64(sbyte value) {unchecked{ return value >= 0 ? (byte)value : 0UL; }}
	public static ulong u64(byte value) { return value; }
	public static ulong u64(short value) {unchecked{ return value >= 0 ? (ushort)value : 0UL; }}
	public static ulong u64(ushort value) { return value; }
	public static ulong u64(int value) {unchecked{ return value >= 0 ? (uint)value : 0UL; }}
	public static ulong u64(uint value) { return value; }
	public static ulong u64(long value) {unchecked{ return value >= 0 ? (ulong)value : 0UL; }}
	public static ulong u64(ulong value) { return value; }
	public static ulong u64(float value) { return value <= 0 ? 0UL : value >= 18446744073709551616.0f ? ulong.MaxValue : checked((ulong)value); }
	public static ulong u64(double value) { return value <= 0 ? 0UL : value >= 18446744073709551616.0 ? ulong.MaxValue : checked((ulong)value); }
	public static ulong u64(decimal value) { return value <= 0 ? 0UL : value >= ulong.MaxValue ? ulong.MaxValue : checked((ulong)value); }
	public static ulong u64(System.Numerics.BigInteger value) { return value.Sign <= 0 ? 0UL : value >= ulong.MaxValue ? ulong.MaxValue : (ulong)value; }
}
'@
