unit CustomTypes;

{$mode objfpc}{$H+}

interface


uses
  Classes, SysUtils;
const

{ Overloaded Operators}

{ TPoint add }
operator + (PT1,PT2 : TPoint) : TPoint;

{ TPoint sub }
operator - (PT1,PT2 : TPoint) : TPoint;

{ TPoint comp}
operator = (PT1,PT2 : TPoint) : boolean;

operator >(PT1, PT2: TPoint): boolean;
operator <(PT1, PT2: TPoint): boolean;


type

  TStringArray = array of String;
  T2DStringArray = array of TStringArray;

  PPoint = ^TPoint;

  PPointArray = ^TPointArray;
  TPointArray = array of TPoint;
  P2DPointArray = ^T2DPointArray;
  T2DPointArray = array of TPointArray;

  TVariantArray = Array of Variant;
  PVariantArray = ^TVariantArray;

  PIntegerArray = ^TIntegerArray;
  TIntegerArray = Array of Integer;
  P2DIntArray = ^T2DIntArray;
  T2DIntArray = array of TIntegerArray;
  T2DIntegerArray = T2DIntArray;

  TByteArray = array of Byte;
  T2DByteArray = array of TByteArray;

  TBoolArray = array of boolean;
  TBooleanArray = TBoolArray;
  T2DBoolArray = Array of TBoolArray;

  TExtendedArray = Array of Extended;
  P2DExtendedArray = ^T2DExtendedArray;
  T2DExtendedArray = Array of Array of Extended;

  PBox = ^TBox;
  TBox = record
    x1, y1, x2, y2: Integer;
  end;


implementation

operator+(PT1, PT2: TPoint): TPoint;
begin
  Result.x := PT1.x + PT2.x;
  Result.y := Pt1.y + PT2.y;
end;

operator-(PT1, PT2: TPoint): TPoint;
begin
  Result.x := PT1.x - PT2.x;
  Result.y := Pt1.y - PT2.y;
end;

operator=(PT1, PT2: TPoint): boolean;
begin
  result := ((PT1.x = PT2.x) and (pt1.y = pt2.y));
end;

operator >(PT1, PT2: TPoint): boolean;
begin
  Result := ((PT1.X > PT2.X) and (PT1.Y > PT2.Y));
end;

operator <(PT1, PT2: TPoint): boolean;
begin
  Result := ((PT1.X < PT2.X) and (PT1.Y < PT2.Y));
end;

end.

