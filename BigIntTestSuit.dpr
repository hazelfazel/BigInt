program BigIntTestSuit; {$APPTYPE CONSOLE}

uses
  BigInt, SysUtils, MMsystem;

type
  LongWordArray = array[0..0] of LongWord;
  PLongWordArray = ^LongWordArray;

var
  choice        : String;
  sProgress     : Char = '|';
  iProgress     : Integer = 0;

  sInput        : String = '"Mach schon Platz, ich bin der Landvogt."';
  sOutput       : String;
  nLength       : Integer;

procedure ZeroMemory(Destination: Pointer; Length: LongWord);
begin
  FillChar(Destination^, Length, 0);
end;

///////////////////////////////////////////////////////////////
//  rsa_encrypt:
//
//  e = public key
//  m = modulos shipped with public key (m MUST contain at least 2 digits)
//  pInBuffer = Buffer to encrypt. Note: Buffer MUST contain at least 1 Byte
//  pOutBuffer = Buffer that contains the encrypted pInBuffer
//  nInLength = Length of pInBuffer in Bytes
//  nOutLength = Length of pOutBuffer in Bytes. After encryption nOutLength contains number of bytes used
function rsa_encrypt(const e, m: TBigInt; pInBuffer, pOutBuffer: PLongWordArray; nInLength: Integer; var nOutLength: Integer): Boolean;
var
  i, j, k: Integer;
  dummy  : TBigInt;
begin
  Result := False;

  dummy := TBigInt.Create;
  j := 0; k := 0;
  if (m.DigitCount > 1) and (nLength > 0) then
    while (j*4 < nInLength) do
    begin
      dummy.Clear;
      dummy.Digit[m.DigitCount - 1] := 1;
      for i := 0 to m.DigitCount - 2 do
        if ((j+i)*4 < nInLength) then
          dummy.Digit[i] := pInBuffer[j+i]
        else
          dummy.Digit[i] := 0;
      j := j + m.DigitCount - 1;
      dummy.modPow(e, m);
      for i := 0 to dummy.DigitCount - 1 do
        if (((i+k)*4) < nOutLength) then
          pOutBuffer[i+k] := dummy.Digit[i];
      k := k + dummy.DigitCount;
    end;
  if (m.DigitCount > 1) and (nOutLength <= k*4) and (nInLength > 0) then
    Result := True;
  nOutLength := k*4;
  dummy.Free;
end;

///////////////////////////////////////////////////////////////
//  rsa_decrypt:
//
//  d = private key
//  m = modulos shipped with public key (m MUST contain at least 2 digits)
//  pInBuffer = Buffer to decrypt. Note: Buffer MUST contain at least 1 Byte
//  pOutBuffer = Buffer that contains the decrypted pInBuffer
//  nInLength = Length of pInBuffer in Bytes
//  nOutLength = Length of pOutBuffer in Bytes. After decryption nOutLength contains number of bytes used
function rsa_decrypt(const d, m: TBigInt; pInBuffer, pOutBuffer: PLongWordArray; nInLength: Integer; var nOutLength: Integer): Boolean;
var
  i, j, k: Integer;
  dummy  : TBigInt;
begin
  Result := False;

  dummy := TBigInt.Create;
  j := 0; k := 0;
  if (m.DigitCount > 1) and (nLength > 0) then
    while (j*4 < nInLength) do
    begin
      for i := 0 to m.DigitCount - 1 do
        if ((j+i)*4 < nInLength) then
          dummy.Digit[i] := pInBuffer[j+i]
        else
          dummy.Digit[i] := 0;
      j := j + m.DigitCount;
      dummy.modPow(d, m);
      for i := 0 to dummy.DigitCount - 2 do
        if ((i+k)*4 < nOutLength) then
          pOutBuffer[i+k] := dummy.Digit[i];
      k := k + dummy.DigitCount - 1;
    end;
  if (m.DigitCount > 1) and (nOutLength <= k*4) and (nInLength > 0) then
    Result := True;
  nOutLength := k*4;
  dummy.Free;
end;

procedure generate_key;
var
  TWO           : TBigInt;
  i             : Integer;
  p, q, x, y    : TBigInt;
  e, d, m, phi_m: TBigInt;
  t1, t2, t3    : Cardinal;
  CRYPTO_DIGITS : Integer;
  sigA          : Integer;
begin
  CRYPTO_DIGITS := 1;
  repeat
    write('? Enter number of digits (1 digit = 32 bits): ');
    try
      readln(CRYPTO_DIGITS);
    except
      ;
    end;
  until (CRYPTO_DIGITS>0) and (CRYPTO_DIGITS<=64);
  writeln('> generating ~'+IntToStr((CRYPTO_DIGITS)*32*2)+'bit keypair.');
  randomize;
  i:=random(TimeGetTime+256);
  while (i>0) do
  begin
    random($FFFFFFFF);
    dec(i);
  end;

  TWO := TBigInt.Create(2);

  p := TBigInt.Create(0);
  for i:=0 to CRYPTO_DIGITS do
    p.Digit[i] := random($FFFFFFFF);
  p.Digit[0] := p.Digit[0] or 1;
  t1 := TimeGetTime;
  repeat
    case iProgress of
      0: begin inc(iProgress); sProgress:='/'; end;
      1: begin inc(iProgress); sProgress:='-'; end;
      2: begin inc(iProgress); sProgress:='\'; end;
      3: begin iProgress:=0; sProgress:='|'; end;
    end;
    write(#13'  - random seeking for p ' + sProgress);

    if p.IsProbablePrime(15) then break;
    p.add(TWO);
  until false;
  t2 := TimeGetTime;
  writeln(#13'  - random seeking for p (done) ' + IntToStr(t2-t1));

  q := TBigInt.Create(0);
  for i:=0 to CRYPTO_DIGITS do
    q.Digit[i] := random($FFFFFFFF);
  q.Digit[0] := q.Digit[0] or 1;
  t1 := TimeGetTime;
  repeat
    case iProgress of
      0: begin inc(iProgress); sProgress:='/'; end;
      1: begin inc(iProgress); sProgress:='-'; end;
      2: begin inc(iProgress); sProgress:='\'; end;
      3: begin iProgress:=0; sProgress:='|'; end;
    end;
    write(#13'  - random seeking for q ' + sProgress);

    if q.IsProbablePrime(15) then break;
    q.add(TWO);
  until false;
  t2 := TimeGetTime;
  writeln(#13'  - random seeking for q (done) ' + IntToStr(t2-t1));

  p.Digit[0] := p.Digit[0] and $FFFFFFFE; // p-1 (just AND it out because p is odd)
  q.Digit[0] := q.Digit[0] and $FFFFFFFE; // q-1 (just AND it out because p is odd)
  phi_m := TBigInt.Create(p);
  phi_m.mul(q); // phi_m = (p-1) * (q-1)
  p.Digit[0] := p.Digit[0] or $00000001; // restore p (add one)
  q.Digit[0] := q.Digit[0] or $00000001; // restore q (add one)
  m := TBigInt.Create(p);
  m.mul(q);

  writeln('  - generating private- and public key out of p and q...');
  x := TBigInt.Create(0);
  y := TBigInt.Create(0);
  d := TBigInt.Create(1);
  e := TBigInt.Create(65537); //1979
  e.xeuclid(phi_m, x, d, y);
  if (d.IsNegative) then
    d.add(phi_m);

  writeln('> checking generated key pair... ');
  x.Clear;
  x.Assign(e);
  x.mul(d);
  x.mod_(phi_m);
  writeln('  - phase (a) passed with ' + x.ToString);
  if (x.Digit[0] = 1) then
  begin
    x.Free;
    x := TBigInt.Create('1234567890'); // Message x
    t1:=TimeGetTime;
    x.modPow(e, m); // Encrypt message: x^(e) mod m
    t2:=TimeGetTime;
    x.modPow(d, m); // Decrypt message: x^(d) mod m
    t3:=TimeGetTime;
    writeln('  - phase (b) passed with ' + x.ToString);

    sigA:=(m.DigitCount*32)-1;
    while (sigA>0) and ((m.Digit[sigA div 32] and (1 shl (sigA mod 32)))=0) do dec(sigA);
    writeln('  - m uses ' + IntToStr(sigA) + 'bits.');
    
    if (x.ToString = '1234567890') then
      writeln('  - keypair passed integrity-check.')
    else
      writeln('  - keypair did not pass integrity-check. Please contact peanut@bitnuts.de and include the following values - thank you!');

    writeln('> Performance: ' + IntToStr(t2-t1) + '/' + IntToStr(t3-t2)+' ms');

    writeln('> Calculated values:');
    writeln('  - p: ' + p.ToString);
    writeln('  - q: ' + q.ToString);
    writeln('  - m: ' + m.ToString);
    writeln('  - e: ' + e.ToString);
    writeln('  - d: ' + d.ToString);
    writeln;

    SetLength(sOutput, 1024);
    ZeroMemory(@sOutput[1], Length(sOutput));
    nLength := Length(sOutput);
    rsa_encrypt(e, m, @sInput[1], @sOutput[1], Length(sInput), nLength);
    SetLength(sOutput, nLength);
    sInput := sOutput;
    SetLength(sOutput, 1024);
    ZeroMemory(@sOutput[1], Length(sOutput));
    nLength := Length(sOutput);
    rsa_decrypt(d, m, @sInput[1], @sOutput[1], Length(sInput), nLength);
    sInput := Trim(sOutput);
    writeln('> en/decrypted message: ' + sInput);
  end;

  writeln;

  p.Free;
  q.Free;
  phi_m.Free;
  x.Free;
  y.Free;
  e.Free;
  d.Free;
  m.Free;
  TWO.Free;
end;

begin
  writeln('# BigInt-Testsuit Copyright (c) 2005-2006 by F. Rienhardt');
   repeat
     writeln;
     writeln('  <1> Build private/public key and do a RSA en/decryption test');
     writeln;
     writeln('  <q> Quit');
     writeln;
     write('? Make a choice: ');
     readln(choice);
     if (choice='1') then generate_key;
   until (choice='q') or (choice='Q');
end.
