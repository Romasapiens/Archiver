unit Huffman;

interface
uses
  SysUtils;

function DecompressData(const CompressedData: TBytes): TBytes;
function CompressData(const Data: TBytes; FullFlName: String): TBytes;

implementation

type
  TNode = record
    Symbol : Byte;
    Frequency : integer;
    Left : integer;
    Right : integer;
  end;
  TNodeArray = array of TNode;
  TFrequencies = array[0..255] of Integer;
  TCodes = array[0..255] of string;

//подсчет частот символов
procedure CountFrequencies(const Data: TBytes; var Frequencies: TFrequencies);
var
  i: Integer;
begin
  FillChar(Frequencies, SizeOf(Frequencies), 0);
  for i := 0 to High(Data) do
    Inc(Frequencies[Data[i]]);
end;

// Построение дерева Хаффмана
function BuildHuffmanTree(const Frequencies: TFrequencies; var Nodes: TNodeArray): Integer;
var
  NodeCount, Min1, Min2: Integer;
  NoRoot: boolean;

  procedure AddNode(Symbol: Byte; Frequency: Integer);
  begin
    if NodeCount >= Length(Nodes) then
      SetLength(Nodes, Length(Nodes) + 256);
    Nodes[NodeCount].Symbol := Symbol;
    Nodes[NodeCount].Frequency := Frequency;
    Nodes[NodeCount].Left := -1;
    Nodes[NodeCount].Right := -1;
    Inc(NodeCount);
  end;

  procedure FindTwoMinNodes(var Min1, Min2: Integer);
  var
    i: Integer;
    f1, f2: Integer;
  begin
    Min1 := -1;
    Min2 := -1;
    f1 := MaxInt;
    f2 := MaxInt;
    for i := 0 to NodeCount - 1 do
    begin
      if (Nodes[i].Frequency > 0) and (Nodes[i].Frequency < f1) then
      begin
        f2 := f1;
        Min2 := Min1;
        f1 := Nodes[i].Frequency;
        Min1 := i;
      end
      else if (Nodes[i].Frequency > 0) and (Nodes[i].Frequency < f2) then
      begin
        f2 := Nodes[i].Frequency;
        Min2 := i;
      end;
    end;
  end;

begin
  NoRoot := True;
  SetLength(Nodes, 256);
  NodeCount := 0;
  for var i := 0 to 255 do
    if Frequencies[i] > 0 then
      AddNode(i, Frequencies[i]);

  while NoRoot do
  begin
    FindTwoMinNodes(Min1, Min2);
    if Min2 = -1 then NoRoot := False
    else
    begin
      AddNode(0, Nodes[Min1].Frequency + Nodes[Min2].Frequency);
      Nodes[NodeCount-1].Left := Min1;
      Nodes[NodeCount-1].Right := Min2;
      Nodes[Min1].Frequency := -1;
      Nodes[Min2].Frequency := -1;
    end;
  end;

  Result := NodeCount - 1;
end;

//генерация кодов символов
procedure GenerateCodes(NodeIndex: Integer; const Nodes: TNodeArray; var Codes: TCodes; CurrentCode: string);
begin
  if not(NodeIndex = -1) then
  begin

    if (Nodes[NodeIndex].Left = -1) and (Nodes[NodeIndex].Right = -1) then
    begin
      Codes[Nodes[NodeIndex].Symbol] := CurrentCode;
    end
    else
    begin
      GenerateCodes(Nodes[NodeIndex].Left, Nodes, Codes, CurrentCode + '0');
      GenerateCodes(Nodes[NodeIndex].Right, Nodes, Codes, CurrentCode + '1');
    end;
  end;
end;
// Запись битов в буфер
procedure WriteBits(const Code: string; var BitBuffer: Byte; var BitCount: Integer; var Output: TBytes);
var
  i: Integer;
  Bit: Byte;
begin
  for i := 1 to Length(Code) do
  begin
    Bit := Ord(Code[i] = '1');
    BitBuffer := (BitBuffer shl 1) or Bit;
    Inc(BitCount);
    if BitCount = 8 then
    begin
      SetLength(Output, Length(Output) + 1);
      Output[High(Output)] := BitBuffer;
      BitBuffer := 0;
      BitCount := 0;
    end;
  end;
end;

// Сжатие данных
function CompressData(const Data: TBytes; FullFlName: String): TBytes;
var
  Frequencies: TFrequencies;
  Nodes: TNodeArray;
  Codes: TCodes;
  BitBuffer, LastByteBits: Byte;
  BitCount, RootIndex, Lfn: Integer;
  sad: TBytes;
begin
  CountFrequencies(Data, Frequencies);
  RootIndex := BuildHuffmanTree(Frequencies, Nodes);
  GenerateCodes(RootIndex, Nodes, Codes, '');
  BitBuffer := 0;
  BitCount := 0;
  sad := TEncoding.UTF8.GetBytes(FullFlName);
  Lfn := Length(sad);
  SetLength(Result, Lfn + 2);
  //тип архивации
  Result[0] := 0;
  //длина имени, имя
  Result[1] := Lfn;
  for var j := 1 to Lfn do
    Result[j+1] := sad[j-1];

  // Запись частот
  for var i := 0 to 255 do
  begin
    SetLength(Result, Length(Result) + 4);
    PInteger(@Result[Length(Result)-4])^ := Frequencies[i];
  end;
  //обработка случая для одного символа
  if Length(Data) = 1 then
  begin
    SetLength(Result, Length(Result)+1);
    Result[High(Result)] := 0;
  end
  else
  begin
  // Кодирование данных
  for var i := 0 to High(Data) do
    WriteBits(Codes[Data[i]], BitBuffer, BitCount, Result);

  // Дополнение последнего байта
  LastByteBits := BitCount;
  if BitCount > 0 then
  begin
    BitBuffer := BitBuffer shl (8 - BitCount);
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := BitBuffer;
  end;

  // Добавляем информацию о количестве битов в последнем байте (1 байт)
  SetLength(Result, Length(Result) + 1);
  Result[High(Result)] := LastByteBits;
  end;
end;

// Распаковка данных
function DecompressData(const CompressedData: TBytes): TBytes;
var
  Frequencies: TFrequencies;
  Nodes: TNodeArray;
  Pos, i: Integer;
  CurrentNode, RootIndex: Integer;
  ByteData, LastByteBits, BitsToProcess: Byte;
  IsLastByte : boolean;
begin
  // Чтение частот
  Pos := CompressedData[1] + 2;
  for i := 0 to 255 do
  begin
    Frequencies[i] := PInteger(@CompressedData[Pos])^;
    Inc(Pos, 4);
  end;
  //Обработка случая для одного символа
  if Length(CompressedData) = 1025 + CompressedData[1] + 2 then
  begin
    i := 0;
    SetLength(Result, 0);
    while (i < 256) and (Length(Result) <> 1) do
    begin
      if Frequencies[i] > 0 then
      begin
        SetLength(Result, 1);
        Result[0] := i;
      end;
      Inc(i);
    end;
  end
  else
  begin
  // Чтение информации о последнем байте (последний байт массива)
  LastByteBits := CompressedData[High(CompressedData)];
  // Построение дерева
  RootIndex := BuildHuffmanTree(Frequencies, Nodes);
  CurrentNode := RootIndex;
  Result := nil;

  // Декодирование
  while Pos < Length(CompressedData)-1 do
  begin
    ByteData := CompressedData[Pos];
    Inc(Pos);

    IsLastByte := (Pos = High(CompressedData));
    if IsLastByte and (LastByteBits > 0) then
      BitsToProcess := LastByteBits
    else BitsToProcess := 8;

    for var BitPos := 7 downto (8 - BitsToProcess) do
    begin
      if (ByteData and (1 shl BitPos)) <> 0 then
        CurrentNode := Nodes[CurrentNode].Right
      else
        CurrentNode := Nodes[CurrentNode].Left;

      if (Nodes[CurrentNode].Left = -1) and (Nodes[CurrentNode].Right = -1) then
      begin
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)] := Nodes[CurrentNode].Symbol;
        CurrentNode := RootIndex;
      end;
    end;
  end;
  end;
end;

end.
