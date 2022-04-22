{
  BigInt Class Version 2.4.3

  Copyright (c) 2003-2006, F. Rienhardt aka peanut ["copyright holder(s)"]
  Donations ? Questions ? Suggestions ?
  Contact: peanut (at) bitnuts.de

  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice, this
     list of conditions and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright notice,
     this list of conditions and the following disclaimer in the documentation
     and/or other materials provided with the distribution.
  3. The name(s) of the copyright holder(s) may not be used to endorse or
     promote products derived from this software without specific prior written
     permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY
  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}

unit BigInt;

interface


{$define TrivialPrimeDivisorTest}


uses
  SysUtils;

type
   TBigInt = class(TObject)
     protected
        FDigits  :  array of LongWord;
        FNegative:  Boolean;

     public
        // (de)initialization stuff...
        constructor Create; overload;
        constructor Create(value: Integer); overload;
        constructor Create(value: String); overload;
        constructor Create(const value: TBigInt); overload;
        destructor  Destroy; override;

        // Internal functions to play around with the Digits directly
        procedure   Assign(const value: TBigInt);
        procedure   Clear;
        procedure   Trim;
        procedure   SetDigit(index: Integer; value: LongWord);
        function    GetDigit(index: Integer): LongWord;
        function    DigitCount: Integer;

        // Input/Output functions to handle BigInts as strings
        function    ToString: String;
        function    ToHexString: String;

        // Stuff you need to make decisions
        function    IsNegative: Boolean;
        function    IsZero: Boolean;
        function    IsOdd: Boolean;
        function    IsEven: Boolean;
        function    IsGreater(const value: TBigInt): Boolean;
        function    IsEqual(const value: TBigInt): Boolean;
        function    IsLess(const value: TBigInt): Boolean;
        function    IsGreaterOrEqual(const value: TBigInt): Boolean;
        function    IsLessOrEqual(const value: TBigInt): Boolean;
        function    IsProbablePrime(steps: Integer): Boolean;

        // Artihmetics
        procedure   abs;
        procedure   neg;
        procedure   add(const value: TBigInt);
        procedure   sub(const value: TBigInt);
        procedure   mul(const value: TBigInt);
        procedure   div_(const value: TBigInt);
        procedure   mod_(const value: TBigInt);
        procedure   div_mod(const value: TBigInt; var modulos: TBigInt);
        procedure   gcd(const value: TBigInt);
        procedure   modPow(const value, m: TBigInt);
        procedure   xeuclid(const value, d, x, y: TBigInt);
        procedure   BarrettReduction(const m, constant: TBigInt; k: Integer);
        procedure   Square;

        // Logical functions
        procedure   shr_(index: Integer);
        procedure   shl_(index: Integer);
        // ... to do ... and, or, xor, not, nor, nand ... that`s too simple for me :-)

        property    Digit[index: Integer]: Cardinal read GetDigit write SetDigit;
     end;


implementation


// primes between 0 and 2.000 - this list will be helpful to perform a
// primitive primality check.
const maxPrimeIndex = 302;
      primes : array[0..maxPrimeIndex] of Integer =
                (2,   3,   5,   7,  11,  13,  17,  19,  23,  29,
                31,  37,  41,  43,  47,  53,  59,  61,  67,  71,
                73,  79,  83,  89,  97, 101, 103, 107, 109, 113,
               127, 131, 137, 139, 149, 151, 157, 163, 167, 173,
               179, 181, 191, 193, 197, 199, 211, 223, 227, 229,
               233, 239, 241, 251, 257, 263, 269, 271, 277, 281,
               283, 293, 307, 311, 313, 317, 331, 337, 347, 349,
               353, 359, 367, 373, 379, 383, 389, 397, 401, 409,
               419, 421, 431, 433, 439, 443, 449, 457, 461, 463,
               467, 479, 487, 491, 499, 503, 509, 521, 523, 541,
               547, 557, 563, 569, 571, 577, 587, 593, 599, 601,
               607, 613, 617, 619, 631, 641, 643, 647, 653, 659,
               661, 673, 677, 683, 691, 701, 709, 719, 727, 733,
               739, 743, 751, 757, 761, 769, 773, 787, 797, 809,
               811, 821, 823, 827, 829, 839, 853, 857, 859, 863,
               877, 881, 883, 887, 907, 911, 919, 929, 937, 941,
               947, 953, 967, 971, 977, 983, 991, 997,1009,1013,
              1019,1021,1031,1033,1039,1049,1051,1061,1063,1069,
              1087,1091,1093,1097,1103,1109,1117,1123,1129,1151,
              1153,1163,1171,1181,1187,1193,1201,1213,1217,1223,
              1229,1231,1237,1249,1259,1277,1279,1283,1289,1291,
              1297,1301,1303,1307,1319,1321,1327,1361,1367,1373,
              1381,1399,1409,1423,1427,1429,1433,1439,1447,1451,
              1453,1459,1471,1481,1483,1487,1489,1493,1499,1511,
              1523,1531,1543,1549,1553,1559,1567,1571,1579,1583,
              1597,1601,1607,1609,1613,1619,1621,1627,1637,1657,
              1663,1667,1669,1693,1697,1699,1709,1721,1723,1733,
              1741,1747,1753,1759,1777,1783,1787,1789,1801,1811,
              1823,1831,1847,1861,1867,1871,1873,1877,1879,1889,
              1901,1907,1913,1931,1933,1949,1951,1973,1979,1987,
              1993,1997, 1999);

var
  bufdvsr: array [0..31] of TBigInt;

procedure ZeroMemory(Destination: Pointer; Length: LongWord);
begin
  FillChar(Destination^, Length, 0);
end;


//-------- Create (public) -----------------------------------------------
constructor TBigInt.Create;
begin
  inherited Create;
  SetLength(FDigits, 1);
  FDigits[0] := 0;
  FNegative := False;
end;


//-------- Create (public) -----------------------------------------------
constructor TBigInt.Create(value: Integer);
begin
  inherited Create;
  SetLength(FDigits, 1);
  if (value >=0) then
  begin
    FDigits[0] := value;
    FNegative := False;
  end else begin
    FDigits[0] := -value;
    FNegative := True;
  end;
end;


//-------- Create (public) -----------------------------------------------
// Create BigInt by a Base10-String
constructor TBigInt.Create(value: String);
var
  radix    : TBigInt;
  dummy    : TBigInt;
  i        : Integer;
begin
  inherited Create;

  SetLength(FDigits, 1);
  FDigits[0] := 0;
  FNegative := False;
  
  if (value<>'') then
  begin
    radix := TBigInt.Create(10);
    dummy := TBigInt.Create(0);
    i := 1;
    if (value[1] = '-') then
      i := 2;
    while (i <= Length(value)) do
    begin
      Self.mul(radix);
      dummy.FDigits[0] := Ord(value[i])-48;
      Self.add(dummy);
      inc(i);
    end;
    if (value[1] = '-') then
      FNegative := True;
    dummy.Free;
    radix.Free;
  end;
end;


//-------- Create (public) -----------------------------------------------
constructor TBigInt.Create(const value: TBigInt);
begin
  inherited Create;
  Assign(value)
end;


//-------- Destroy (public) -----------------------------------------------
destructor TBigInt.Destroy;
begin 
  ZeroMemory(@FDigits[0], DigitCount*4); // object might handle prime factors for
  SetLength(FDigits, 0);                 // crypto keys - overwrite memory with zeros
  FNegative := False;
  inherited; 
end;


//-------- Assign (public) ---------------------------------------------
procedure TBigInt.Assign(const value: TBigInt);
begin
  SetLength(FDigits, value.DigitCount);
  Move(value.FDigits[0], FDigits[0], value.DigitCount*4);
  FNegative := value.FNegative;
end;


//-------- Clear (public) ---------------------------------------------
procedure TBigInt.Clear;
begin
  ZeroMemory(@FDigits[0], DigitCount*4);
  SetLength(FDigits, 1);
  FNegative := False;
end;


//-------- Trim (public) ---------------------------------------------
procedure TBigInt.Trim;
var
  i: Integer;
begin
  i := DigitCount-1;
  while (i > 0) and (FDigits[i] = 0) do dec(i);
  SetLength(FDigits, i+1);
  if (DigitCount = 1) and (FDigits[0] = 0) then
    FNegative := False;
end;


//-------- SetDigit (public) -----------------------------------------------
procedure TBigInt.SetDigit(index: Integer; value: LongWord);
var
  i: Integer;
begin
  if (index >= DigitCount) then
  begin
    i := DigitCount;
    SetLength(FDigits, index+1);
    ZeroMemory(@FDigits[i], index-i);
  end;
  FDigits[index] := value;
end;


//-------- GetDigit (public) -----------------------------------------------
function TBigInt.GetDigit(index: Integer): LongWord;
begin
  if (index >= DigitCount) then
    Result := 0
  else
    Result := FDigits[index];
end;


//-------- DigitCount (public) -----------------------------------------------
function TBigInt.DigitCount: Integer;
begin
  Result := Length(FDigits);
end;


//-------- ToString (public) -----------------------------------------------
function TBigInt.ToString: String;
var
  radix    : TBigInt;
  dummy    : TBigInt;
  remainder: TBigInt;
  sTemp    : String;
begin
  if (IsZero) then
    Result := '0'
  else begin
    Result := '';
    radix := TBigInt.Create(1000000000);
    dummy := TBigInt.Create(Self);
    remainder := TBigInt.Create(Self);
    while not(dummy.IsZero) do
    begin
      //remainder.mod_(radix);
      //dummy.div_(radix);
      dummy.div_mod(radix, remainder);
      sTemp := IntToStr(remainder.Digit[0]);
      if not(dummy.IsZero) then
        while (Length(sTemp) < 9) do sTemp := '0' + sTemp;
      Result := sTemp + Result;
      remainder.Assign(dummy);
    end;
    remainder.Free;
    dummy.Free;
    radix.Free;
    if (IsNegative) then
      Result := '-' + Result;
  end;
end;


//-------- ToString (public) -----------------------------------------------
function TBigInt.ToHexString: String;
var
  i: Integer;
begin
  Result := '';

  i:=DigitCount-1;
  while (FDigits[i] = 0) and (i > 0) do dec(i);
  while (i >= 0) do
  begin
    Result := Result + LowerCase(Format('%.8x', [FDigits[i]]));
    dec(i);
  end;
  if (IsNegative) then
    Result := '-' + Result;
end;


//-------- IsNegative (public) -----------------------------------------------
function TBigInt.IsNegative: Boolean;
begin
  Result := FNegative;
end;


//-------- IsZero (public) -----------------------------------------------
function TBigInt.IsZero: Boolean;
var
  i: Integer;
begin
  Result := True;

  for i:=0 to DigitCount-1 do
    if (FDigits[i] <> 0) then
    begin
      Result := False;
      Break;
    end;
end;


//-------- IsOdd (public) -----------------------------------------------
function TBigInt.IsOdd: Boolean;
begin
  if ((FDigits[0] and $1) <> 0) and not(IsZero) then
    Result := True
  else
    Result := False;
end;


//-------- IsEven (public) -----------------------------------------------
function TBigInt.IsEven: Boolean;
begin
  Result := not(IsOdd);
end;


//-------- IsGreater (public) -----------------------------------------------
function TBigInt.IsGreater(const value: TBigInt): Boolean;
var
  i: Integer;
  maxDigit: Integer;
begin
  // signs are not equal
  if (IsNegative <> value.IsNegative) then
    Result := value.IsNegative
  else begin
    // equal signs...
    if (DigitCount >= value.DigitCount) then
      maxDigit := DigitCount
    else
      maxDigit := value.DigitCount;

    i := maxDigit-1;
    while (i >= 0) and (Digit[i] = value.Digit[i]) do dec(i);
    if (i >= 0) and (Digit[i] > value.Digit[i]) then
      Result := True
    else
      Result := False;
  end;
end;


//-------- IsEqual (public) -----------------------------------------------
function TBigInt.IsEqual(const value: TBigInt): Boolean;
var
  i: Integer;
  maxDigit: Integer;
begin
  if (FNegative = value.FNegative) then
  begin
    if (DigitCount >= value.DigitCount) then
      maxDigit := DigitCount
    else
      maxDigit := value.DigitCount;
    i := 0;
    while (i < maxDigit) and (Digit[i] = value.Digit[i]) do inc(i);
    if (i < maxDigit) and (Digit[i] <> value.Digit[i]) then
      Result := False
    else
      Result := True;
  end else
    Result := False;
end;


//-------- IsLess (public) -----------------------------------------------
function TBigInt.IsLess(const value: TBigInt): Boolean;
var
  i: Integer;
  maxDigit: Integer;
begin
  // signs are not equal
  if (IsNegative <> value.IsNegative) then
    Result := IsNegative
  else begin
    // equal signs
    if (DigitCount >= value.DigitCount) then
      maxDigit := DigitCount
    else
      maxDigit := value.DigitCount;

    i := maxDigit-1;
    while (i >= 0) and (Digit[i] = value.Digit[i]) do dec(i);
    if (i >= 0) and (Digit[i] < value.Digit[i]) then
      Result := True
    else
      Result := False;
  end;
end;


//-------- IsGreaterOrEqual (public) -----------------------------------------------
function TBigInt.IsGreaterOrEqual(const value: TBigInt): Boolean;
begin
  if (IsGreater(value)) or (IsEqual(value)) then
    Result := True
  else
    Result := False;
end;


//-------- IsLessOrEqual (public) -----------------------------------------------
function TBigInt.IsLessOrEqual(const value: TBigInt): Boolean;
begin
  if (IsLess(value)) or (IsEqual(value)) then
    Result := True
  else
    Result := False;
end;


//-------- IsProbablePrime (public) -----------------------------------------------
// The Miller-Rabin Algorithm based on an algorithm as described in
// "Introduction to Datastructures", Springer 2000
function TBigInt.IsProbablePrime(steps: Integer): Boolean;
var
  i, t            : Integer;
  dummy1, dummy2  : TBigInt;
  U, P_1, ONE, TWO: TBigInt;
  sgn             : Boolean;
begin
  Result := False;
  
  if not(IsZero) and ((Digit[0] and 1)<>0) then
  begin
    sgn := FNegative;
    FNegative := False;
    
    // maybe a prime, 'cause it is odd
    Result := True;

    dummy1 := TBigInt.Create(0);
    dummy2 := TBigInt.Create(Self);

    // try to find a trivial prime-divisor within the first
    // primes in the primes-array.
    {$ifdef TrivialPrimeDivisorTest}
    i:=0;
    while (Result = True) and (i < maxPrimeIndex) do
    begin
      dummy1.FDigits[0] := primes[i];
      dummy2.mod_(dummy1);
      if (dummy2.IsZero) and not(IsEqual(dummy1)) then
        Result := False;
      dummy2.Assign(Self);
      inc(i);
    end;
    dummy1.Clear;
    {$endif}

    // If trivial prime-divisor test says true, we enter Miller-Rabin
    // because until now it is not clear if number is prime.
    if (Result = True) then
    begin
      U := TBigInt.Create(Self);
      U.FDigits[0] := U.FDigits[0] and $FFFFFFFE;
      t := 0;
      while ((t div 32) < U.DigitCount) and ( (U.Digit[t div 32] and (1 shl (t mod 32)) ) = 0) do
        inc(t);
      U.shr_(t);
      if (U.IsZero) then
        Result := False;

      ONE := TBigInt.Create(1);
      TWO := TBigInt.Create(2);
      P_1 := TBigInt.Create(Self);
      P_1.FDigits[0] := P_1.FDigits[0] and $FFFFFFFE;

      while (Result = True) and (steps > 0) do
      begin
        dummy1.Clear;
        dummy1.FDigits[0] := primes[random(maxPrimeIndex+1)];

        dummy1.modPow(U, self);
        dummy2.Assign(dummy1);
        for i := 1 to t do
        begin
          dummy2.modPow(TWO, Self);
          if (dummy2.IsEqual(ONE)) and not(dummy1.IsEqual(ONE)) and not(dummy1.IsEqual(P_1)) then
          begin
            Result := False;
            Break;
          end;
          dummy1.Assign(dummy2);
        end;
        if (i > t) and not(dummy1.IsEqual(ONE)) then
          Result := False;
        dec(steps);
      end;
      
      ONE.Free;
      TWO.Free;
      P_1.Free;
      U.Free;

      FNegative := sgn;
    end;

    dummy1.Free;
    dummy2.Free;
  end;
end;


//-------- abs (public) -----------------------------------------------
procedure TBigInt.abs;
begin
  FNegative := False;
end;


//-------- neg (public) -----------------------------------------------
procedure TBigInt.neg;
begin
  FNegative := not(FNegative);
end;


procedure second_complement(const value: TBigInt);
var
  sum     : Int64;
  carry   : Int64;
  i       : Integer;
begin
  if not(value.IsZero) then
  begin
    carry := 1;
    if (value.IsNegative) then
      for i := 0 to value.DigitCount-1 do
      begin
        sum              := Int64(not(value.FDigits[i])) + Int64(carry);
        carry            := Int64(sum) shr Int64(32);
        value.FDigits[i] := sum and $FFFFFFFF;
      end;
  end;
end;



//-------- add (public) -----------------------------------------------
procedure TBigInt.add(const value: TBigInt);
var
  sum     : Int64;
  carry   : Int64;
  i       : Integer;
  maxDigit: Integer;
begin
  if (DigitCount >= value.DigitCount) then
    maxDigit := DigitCount
  else
    maxDigit := value.DigitCount;
  Digit[maxDigit] := 0;
  value.Digit[maxDigit] := 0;

  // negative BigInteger values must first be brought to 2th complement...
  second_complement(Self);
  if (Self <> value) then
    second_complement(value);

  carry := 0;
  for i := 0 to DigitCount-1 do
  begin
    sum        := Int64(FDigits[i]) + Int64(value.FDigits[i]) + Int64(carry);
    carry      := Int64(sum) shr Int64(32);
    FDigits[i] := sum and $FFFFFFFF;
  end;

  if (FDigits[DigitCount-1] and $80000000 <> 0) then
    FNegative := True
  else
    FNegative := False;

  // convert 2th complement to normal integer
  second_complement(Self);
  if (Self <> value) then
    second_complement(value);
  Trim();
  value.Trim();
end;


//-------- sub (public) -----------------------------------------------
procedure TBigInt.sub(const value: TBigInt);
var
  diff    : Int64;
  carry   : Int64;
  i       : Integer;
  maxDigit: Integer;
begin
  if (DigitCount >= value.DigitCount) then
    maxDigit := DigitCount
  else
    maxDigit := value.DigitCount;
  Digit[maxDigit] := 0;
  value.Digit[maxDigit] := 0;

  // negative BigInteger values must first be brought to 2th complement...
  second_complement(Self);
  if (Self <> value) then
    second_complement(value);

  carry := 0;
  for i := 0 to DigitCount-1 do
  begin
    diff := Int64(FDigits[i]) - Int64(value.FDigits[i]) - Int64(carry);
    FDigits[i] := diff and $FFFFFFFF;
    if (diff < 0) then
      carry := 1
    else
      carry := 0;
  end;

  if (FDigits[DigitCount-1] and $80000000 <> 0) then
    FNegative := True
  else
    FNegative := False;

  // convert 2th complement to normal integer
  second_complement(Self);
  if (Self <> value) then
    second_complement(value);
  Trim();
  value.Trim();
end;


//-------- mul (public) -----------------------------------------------
procedure TBigInt.mul(const value: TBigInt);
var
  result: TBigInt;
  sum   : Int64;
  carry : Int64;
  i, j  : Integer;
begin
  result := TBigInt.Create(0);
  if (DigitCount >= value.DigitCount) then
    result.digit[DigitCount*2] := 0
  else
    result.digit[value.DigitCount*2] := 0;

    for i := 0 to DigitCount-1 do
    if (FDigits[i] <> 0) then
    begin
      carry := 0;
      for j := 0 to value.DigitCount-1 do
      if (carry <> 0) or (value.FDigits[j] <> 0) then
      begin
        sum                 := Int64(result.FDigits[i+j]) + (Int64(FDigits[i]) * Int64(value.FDigits[j])) + carry;
        carry               := (Int64(sum) shr Int64(32)) and $FFFFFFFF;
        result.FDigits[i+j] := sum and $FFFFFFFF;
      end;
      if (carry <> 0) then result.Digit[value.DigitCount+i] := carry;
    end;

  result.FNegative := FNegative xor value.FNegative;
  result.Trim;
  Assign(result);
  result.Free;
end;


//--------- LoadDivArray (protected) -----------------------------------

procedure LoadDivArray(value: TBigInt);
var
  i  : Integer;
begin
  if not(bufdvsr[0].IsEqual(value)) then
  begin
    bufdvsr[0].Assign(value);
    for i := 1 to 31 do
    begin
      bufdvsr[i].Assign(bufdvsr[i-1]);
      bufdvsr[i].shl_(1); // *2
    end;
  end;
end;

function DivDigit(const value: TBigInt): Integer;
var
  i, zw: LongWord;
begin
  Result := 0;
  zw  := 2147483648; //2147483648; // (2^31)
  for i := 31 downto 0 do
  begin
    if value.IsGreaterOrEqual(bufdvsr[i]) then
    begin
      Result := Result + Integer(zw);
      value.sub(bufdvsr[i]);
    end;
    zw := zw div 2;
  end;
end;

//-------- div (public) -----------------------------------------------
// Credits to Roland Mechling, see www.gkinf.de for details.
procedure TBigInt.div_(const value: TBigInt);
var
  r, q      : TBigint;
  d, k, i   : Integer;
  sgn1, sgn2: Boolean;
begin
  q := TBigInt.Create(0);

  sgn1 := FNegative;
  FNegative := False;
  sgn2 := value.FNegative;
  value.FNegative := False;

  if (IsGreaterOrEqual(value)) then
  begin
    r := TBigInt.Create(0);

    i := DigitCount - value.DigitCount;
    for k := DigitCount-1 downto i+1 do
    begin
      r.shl_(32);
      r.Digit[0] := Digit[k];
    end;

    LoadDivArray(value);

    while (i >= 0) do
    begin
      r.shl_(32);
      r.Digit[0] := Digit[i];
      d := DivDigit(r);  // r contains remainder
      q.shl_(32);
      q.Digit[0] := d;
      dec(i);
    end;

    r.Free;
  end;

  q.FNegative := sgn1 xor sgn2;
  q.Trim;
  Assign(q);
  q.Free;
  value.FNegative := sgn2;
end;


//-------- mod (public) -----------------------------------------------
// Credits to Roland Mechling, see www.gkinf.de for details.
procedure TBigInt.mod_(const value: TBigInt);
var
  r, q      : TBigint;
  d, k, i   : Integer;
  sgn1, sgn2: Boolean;
begin
  r := TBigInt.Create(0);

  sgn1 := FNegative;
  FNegative := False;
  sgn2 := value.FNegative;
  value.FNegative := False;

  if (IsGreaterOrEqual(value)) then
  begin
    q := TBigInt.Create(0);

    i := DigitCount - value.DigitCount;
    for k := DigitCount-1 downto i+1 do
    begin
      r.shl_(32);
      r.Digit[0] := Digit[k];
    end;

    LoadDivArray(value);

    while (i >= 0) do
    begin
      r.shl_(32);
      r.Digit[0] := Digit[i];
      d := DivDigit(r);  // r contains remainder
      q.shl_(32);
      q.Digit[0] := d;
      dec(i);
    end;

    q.Free;
  end else r.Assign(self);

  r.FNegative := sgn1;
  r.Trim;
  Assign(r);
  r.Free;
  value.FNegative := sgn2;
end;

//-------- div_mod (public) -----------------------------------------------
// Credits to Roland Mechling, see www.gkinf.de for details.
procedure TBigInt.div_mod(const value: TBigInt; var modulos: TBigInt);
var
  r, q      : TBigint;
  d, k, i   : Integer;
  sgn1, sgn2: Boolean;
begin
  q := TBigInt.Create(0);
  r := TBigInt.Create(0);

  sgn1 := FNegative;
  FNegative := False;
  sgn2 := value.FNegative;
  value.FNegative := False;

  if (IsGreaterOrEqual(value)) then
  begin
    i := DigitCount - value.DigitCount;
    for k := DigitCount-1 downto i+1 do
    begin
      r.shl_(32);
      r.Digit[0] := Digit[k];
    end;

    LoadDivArray(value);

    while (i >= 0) do
    begin
      r.shl_(32);
      r.Digit[0] := Digit[i];
      d := DivDigit(r);  // r contains remainder
      q.shl_(32);
      q.Digit[0] := d;
      dec(i);
    end;

  end else r.Assign(Self);

  q.FNegative := sgn1 xor sgn2;
  q.Trim;
  Assign(q);
  r.FNegative := sgn1;
  r.Trim;
  modulos.Assign(r);
  q.Free;
  r.Free;
  value.FNegative := sgn2;
end;


//-------- gcd (public) -----------------------------------------------
// Based on the binary gcd algorithm as described in
// "Guide to Elliptic Curve Cryptography", Springer 2002
//
// 1.  u = a; v = b; e = 1;
// 2.  while (a is even) and (b is even) do
//       u = u / 2
//       v = v / 2
//       e = e * 2
// 3.  while (u <> 0) do
//       while (u is even) do u = u / 2
//       while (v is even) do v = v / 2
//       if (u >= v) then
//         u = u - v
//       else
//         v = v - u
// 4.  return (e * v) as gcd of input a and b
//
procedure TBigInt.gcd(const value: TBigInt);
var
  u, v, e: TBigInt;
begin
  u := TBigInt.Create(Self);
  v := TBigInt.Create(value);
  e := TBigInt.Create(1);
  u.FNegative := False;
  v.FNegative := False;

  while (u.IsEven) and (v.IsEven) do
  begin
    u.shr_(1);
    v.shr_(1);
    e.shl_(1);
  end;

  while not(u.IsZero) do
  begin
    while (u.IsEven) do u.shr_(1);
    while (v.IsEven) do v.shr_(1);
    if (u.IsGreaterOrEqual(v)) then
      u.sub(v)
    else
      v.sub(u);
  end;

  e.mul(v);
  e.Trim;
  Assign(e);

  e.Free;
  v.Free;
  u.Free;
end;


//-------- modPow (public) -----------------------------------------------
// Based on the extended euclide algorithm as described in
// "Introduction to Datastructures", Springer 2000
procedure TBigInt.modPow(const value, m: TBigInt);
var
  dummy       : TBigInt;
  constant    : TBigInt;
  i, k        : Integer;
  sgn         : Boolean;
begin
  sgn := FNegative;
  FNegative := False;
   
  i := m.DigitCount-1;
  while (i >= 0) and (m.FDigits[i]=0) do dec(i);
  inc(i);
  k := i;
  i := i*2;

  constant := TBigInt.Create(0);
  constant.Digit[i] := $00000001;
  constant.div_(m);
  mod_(m);

  dummy := TBigInt.Create(1);

  for i:=(value.DigitCount*32)-1 downto 0 do
  begin
    dummy.mul(dummy); //dummy.square;
    dummy.BarrettReduction(m, constant, k);
    if (value.Digit[i div 32] and (1 shl (i mod 32)) <> 0) then
    begin
      dummy.mul(Self);
      dummy.BarrettReduction(m, constant, k);
    end;
  end;

  if (sgn) and (value.IsOdd) then
    dummy.FNegative := True;
  dummy.Trim;
  Assign(dummy);
  dummy.Free;
  constant.Free;
end;


//-------- xeuclid (public) -----------------------------------------------
// Based on the extended euclide algorithm as described in
// "Introduction to Datastructures", Springer 2000
procedure TBigInt.xeuclid(const value, d, x, y: TBigInt);
var
  dummy     : TBigInt;
  d_, x_, y_: TBigInt;
begin
  if (value.IsZero) then
  begin
    d.Assign(Self);
    x.Clear;
    x.Digit[0]:=1;
    y.Clear;
  end else begin
    d_ := TBigInt.Create(0);
    x_ := TBigInt.Create(0);
    y_ := TBigInt.Create(0);

    dummy := TBigInt.Create(Self);
    dummy.mod_(value);
    value.xeuclid(dummy, d_, x_, y_);

    dummy.Assign(Self);
    dummy.div_(value);
    dummy.mul(y_);
    x_.sub(dummy);

    d.Assign(d_);
    x.Assign(y_);
    y.Assign(x_);

    dummy.Free;
    d_.Free;
    x_.Free;
    y_.Free;
  end;
end;


//-------- BarretReduction (public) -----------------------------------------------
{
  Algorithm as described in "Handbook of Applied Cryptography", CRC Press, 1996

    1. q1 = x div b^(k-1)
    2. q2 = q1 * [b^(2k) div n]
    3. q3 = q2 div b^(k+1)
    4. r1 = x mod b^(k+1)
    5. r2 = (q3 * n) mod b^(k+1)
    6. r1 = r1 - r2;
    7. if (r1 < 0) then r1 = r1 + b^(k+1)
    8. while (r1 >= n) r1 = r1 - n
    9. return r1

    b = base of digit
    k = sig. digit of number.
    Example: Let`s say we store numbers in DWords - thus the base is 2^32.
             If we store numbers in an array of length 4, a this could
             be an example: (0) (153) (1073741824) (172221345)
             In this case our configuration looks like this
             - k = 3
             - b = 2^32
             - m = (0) (153) (1073741824) (172221345)
}
procedure TBigInt.BarrettReduction(const m, constant: TBigInt; k: Integer);
var
  i,j     : Integer;
  q1      : TBigInt;
  r2      : TBigInt;
  bk1     : TBigInt;
  dummy   : TBigInt;
  sum     : Int64;
  carry   : Int64;
begin
  q1 := TBigInt.Create(0);
  r2 := TBigInt.Create(0);
  dummy := TBigInt.Create(0);

  if (DigitCount >= constant.DigitCount) then
    q1.Digit[DigitCount*2] := 0
  else
    q1.Digit[constant.DigitCount*2] := 0;

    for i := k-1 to DigitCount-1 do
    if (FDigits[i] <> 0) then
    begin
      carry := 0;
      for j := 0 to constant.DigitCount-1 do
      if (carry <> 0) or (constant.FDigits[j] <> 0) then
      begin
        sum                 := Int64(q1.FDigits[i-(k-1)+j]) + (Int64(FDigits[i]) * Int64(constant.FDigits[j])) + carry;
        carry               := (Int64(sum) shr Int64(32)) and $FFFFFFFF;
        q1.FDigits[i-(k-1)+j] := sum and $FFFFFFFF;
      end;
      if (carry <> 0) then q1.Digit[i-(k-1)+constant.DigitCount] := carry;
    end;


  for i := k+1 to DigitCount-1 do
      FDigits[i] := $00000000;

  if (m.DigitCount >= q1.DigitCount) then
    r2.Digit[m.DigitCount*2] := 0
  else
    r2.Digit[q1.DigitCount*2] := 0;

    for i := k+1 to q1.DigitCount-1 do
    begin
      carry := 0;
      for j := 0 to m.DigitCount-1 do
      if (q1.FDigits[i]<>0) and (i-(k+1)+j<k+1) then
      begin
        sum                 := Int64(r2.FDigits[i-(k+1)+j]) + (Int64(q1.FDigits[i]) * Int64(m.FDigits[j])) + carry;
        carry               := (Int64(sum) shr Int64(32)) and $FFFFFFFF;
        r2.FDigits[i-(k+1)+j] := sum and $FFFFFFFF;
      end;
      if (carry <> 0) and (i-(k+1)+m.DigitCount<k+1) then r2.Digit[i-(k+1)+m.DigitCount] := carry;
    end;

  Self.sub(r2);

  if (FNegative) then
  begin
    bk1 := TBigInt.Create(0);
    bk1.Digit[k+1] := $00000001;
    Self.add(bk1);
    bk1.Free;
  end;

  while (Self.IsGreaterOrEqual(m)) do
    Self.sub(m);
  Self.Trim;

  q1.Free;
  r2.Free;
  dummy.Free;
end;


//-------- Square (public) -----------------------------------------------
// Based on the binary gcd algorithm as described in
// "Guide to Elliptic Curve Cryptography", Springer 2002
//
//  Input : a
//  Output: a*a
//
//  a = t-bit number
//  UV = 2t-bit number => U high order and V low order of a 2t-bit word.
//  (c, X) = X is a number using x-bits, c carry flag
//
//
//  1.   R0 = 0, R1 = 0, R2 = 0
//  2.   for k from 0 to 2t-2 do
//  2.1    for each element of {(i,j)|i+j=k, 0<=i<=j<=t-1} do
//           (UV) = A[i] * A[j]
//           if (i < j) do
//             (c, UV) = UV * 2
//             R2 = R2 + c
//           (c, R0) = R0 + V
//           (c, R1) = R1 + U + c
//           R2 = R2 + c
// 2.2     result[k] = R0, R0 = R1, R1 = R2, R2 = 0
// 3.    result[2t-1] = R0
// 4.    return result
//
procedure TBigInt.Square;
begin
  Self.mul(Self);
end;
{procedure TBigInt.Square;
var
  result    : TBigInt;
  UV        : Int64;
  carry     : Int64;
  R0, R1, R2: Int64;
  i, j, k   : Integer;
begin
  result := TBigInt.Create(0);
  result.digit[DigitCount*2] := 0;

  R0 := 0; R1 := 0; R2 := 0;
  for k := 0 to (2*DigitCount)-2 do
  begin
    for i := 0 to DigitCount-1 do
    begin
      for j := i to DigitCount-1 do
      if (i+j = k) then
      begin
        UV := Int64(FDigits[i]) * Int64(FDigits[j]);
        if (i < j) then
        begin
          if ((UV and $8000000000000000) <> 0) then //if (UV < 0) then
            R2 := R2 + 1;
          UV := UV shl 1;
        end;
        R0 := R0 + (UV and $FFFFFFFF);
        carry := R0 shr 32;
        if (carry <> 0) then R0 := R0 and $FFFFFFFF;
        R1 := R1 + (UV shr 32) + carry;
        carry := R1 shr 32;
        if (carry <> 0) then R1 := R1 and $FFFFFFFF;
        R2 := R2 + carry;
        break;
      end;
      if (i+1 > k) then break;
    end;
    result.FDigits[k] := R0 and $FFFFFFFF; R0 := R1; R1 := R2; R2 := 0;
  end;
  result.FDigits[(DigitCount*2)-1] := R0 and $FFFFFFFF;

  result.FNegative := FNegative xor FNegative;
  result.Trim;
  Assign(result);
  result.Free;
end;}


//-------- shr (public) -----------------------------------------------
procedure TBigInt.shr_(index: Integer);
var
  shift        : Int64;
  carry        : Int64;
  i, j         : Integer;
  tmpDigitCount: Integer;
begin
  if (index > 0) then
    if (index >= DigitCount*32) then
      Clear
    else
      begin
        j := 0;
        tmpDigitCount := DigitCount;
        if ((index div 32) > 0) then
          for i := (index div 32) to tmpDigitCount-1 do
          begin
            Digit[j]   := FDigits[i];
            FDigits[i] := 0;
            inc(j)
          end;
        if ((index mod 32) > 0) then
        begin
          carry := 0;
          i := DigitCount-1;
          repeat
            shift      := (Int64(Digit[i]) shr (Int64(index) mod Int64(32))) or carry;
            carry      := (((Int64(Digit[i]) shl Int64(32)) shr (Int64(index) mod Int64(32)))) and Int64($FFFFFFFF);
            FDigits[i] := shift and $FFFFFFFF;
            dec(i);
          until (i < 0);
        end;
        Trim;
      end;
end;


//-------- shl (public) -----------------------------------------------
procedure TBigInt.shl_(index: Integer);
var
  shift        : Int64;
  carry        : Int64;
  i            : Integer;
  tmpDigitCount: Integer;
begin
  if (index > 0) then
  begin
    if ((index div 32) > 0) then
    begin
      tmpDigitCount := DigitCount;
      Digit[DigitCount+(index div 32)] := 0;
      for i := tmpDigitCount-1 downto 0 do
      begin
        FDigits[(index div 32)+i] := FDigits[i];
        FDigits[i]:=0;
      end;
    end;
    if ((index mod 32) > 0) then
    begin
      carry := 0;
      i := (index div 32);
      tmpDigitCount := DigitCount;
      Digit[DigitCount+(index div 32)] := 0;
      repeat
        shift    := (Int64(FDigits[i]) shl (Int64(index) mod 32)) or carry;
        carry    := ((Int64(FDigits[i]) shl (Int64(index) mod 32) shr 32)) and Int64($FFFFFFFF);
        FDigits[i] := shift and $FFFFFFFF;
        inc(i);
      until (i = tmpDigitCount);
      if (carry <> 0) then Digit[i] := carry and $FFFFFFFF;
    end;
    Trim;
  end;
end;


//-------------- Unit-(de)initialization ---------------------------------------


procedure InitDivArray;
var
  i : Integer;
begin
  for i := 0 to Length(bufdvsr)-1 do
    bufdvsr[i] := TBigInt.Create(0);
end;


procedure FreeDivArray;
var
  i : Integer;
begin
  for i := 0 to Length(bufdvsr)-1 do
    bufdvsr[i].Free;
end;


initialization
  InitDivArray;


finalization
  FreeDivArray;


end.
