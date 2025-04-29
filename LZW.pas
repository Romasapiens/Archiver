unit LZW;

interface

uses
  SysUtils;

function CompressData(const InData: TBytes; FullFlName: String): TBytes;
function DecompressData(const InData: TBytes): TBytes;

implementation

type
  // Для промежуточного хранения кодов (каждый код – Word, максимум 4096 записей, то есть 12‐бит).
  TWordArray = array of Word;

{---------------------------------------------------------------------------
  Функция SequencesEqual сравнивает две последовательности (TBytes)
  и возвращает True, если они равны по длине и содержимому.
---------------------------------------------------------------------------}
function SequencesEqual(const A, B: TBytes): Boolean;
var
  i: Integer;
begin
  Result := True;
  if Length(A) <> Length(B) then
    Result := False
  else
  begin
    i := 0;
    while (i <= Length(A) - 1) and Result do
    begin
      if A[i] <> B[i] then
        Result := False;
      Inc(i);
    end;
  end;
end;

{---------------------------------------------------------------------------
  Функция ConcatSequences объединяет две последовательности байт.
---------------------------------------------------------------------------}
procedure ConcatSequences(var Seq1 : TBytes; const Seq2: TBytes);
var
  n1, n2, i: Integer;
begin
  n1 := Length(Seq1);
  n2 := Length(Seq2);
  SetLength(Seq1, n1 + n2);
  for i := 0 to n2 - 1 do
    Seq1[n1+i] := Seq2[i];
end;

{---------------------------------------------------------------------------
  Функция CompressData принимает на вход массив байт (InData) и
  реализует алгоритм LZW для сжатия данных.

  Алгоритм:
  1. Инициализируется словарь, содержащий 256 последовательностей – по одному байту
     (значения 0..255).
  2. Текущая последовательность w итерируется по InData: для каждого нового байта c
     проверяется, содержится ли последовательность wc (w с приписанным c) в словаре.
     Если да – w расширяется до wc, иначе:
       • выводится код для w;
       • в словарь добавляется новая последовательность wc (если не достигли предела 4096);
       • w сбрасывается до [c].
  3. После прохода по входным данным, если w не пуста, её код также выводится.

  Выходной результат – массив байт, где каждый код (Word) записан как два байта.
---------------------------------------------------------------------------}
function CompressData(const InData: TBytes; FullFlName: String): TBytes;
var
  Dictionary: array of TBytes; // Словарь – массив последовательностей байт
  NextCode, i, j, found: Integer;
  w, wc: TBytes;
  c: Byte;
  OutputCodes: TWordArray; // Промежуточный массив кодов (Word)
  CodeCount, Lfn: Integer;
  temp: Word;
  OutBytes, sad: TBytes;
begin
  // Инициализация словаря: создаем 256 записей для каждого отдельного байта.
  SetLength(Dictionary, 257);
  for i := 0 to 255 do
  begin
    SetLength(Dictionary[i], 1);
    Dictionary[i][0] := i;
  end;
  NextCode := 256;

  SetLength(OutputCodes, 0);
  CodeCount := 0;

  // Если входной массив пуст – возвращаем пустой массив.
  // Инициализируем последовательность w первым байтом.
  SetLength(w, 1);
  w[0] := InData[0];

  // Основной цикл – обрабатываем входной массив, начиная со второго элемента.
  for i := 1 to High(InData) do
  begin
    c := InData[i];
    // Формируем новую последовательность wc = w + c.
    wc := Copy(w, 0, Length(w));
    SetLength(wc, Length(wc)+1);
    wc[Length(wc)-1] := c;

    // Поиск wc в словаре.
    found := -1;
    j := 0;
    while (j <= NextCode-1) and (found = -1) do
    begin
      if SequencesEqual(Dictionary[j], wc) then
        found := j;
      Inc(j);
    end;

    if found <> -1 then
    begin
      // Если найдена, расширяем последовательность w.
      w := Copy(wc, 0, Length(wc));
    end
    else
    begin
      // Если не найдена – выводим код для w:
      j := 0;
      while (j <= NextCode-1) and (found = -1) do
      begin
        if SequencesEqual(Dictionary[j], w) then
          found := j;
        Inc(j);
      end;
      Inc(CodeCount);
      SetLength(OutputCodes, CodeCount);
      OutputCodes[CodeCount - 1] := found;
    // Добавляем новую последовательность wc в словарь (если размер не достиг предела 4096).
      if NextCode < 65535 then
      begin
        SetLength(Dictionary, NextCode + 2);
        Dictionary[NextCode] := wc;
        Inc(NextCode);
      end
      else
        raise Exception.Create('Выход размера словаря за 16 бит');
      // Сбрасываем w до значения [c].
      SetLength(w, 1);
      w[0] := c;
    end;
  end;

  // После прохода по всему InData, если последовательность w не пуста – выводим её код.
  found := -1;
  j := 0;
  while (j <= NextCode-1) and (found = -1) do
      begin
        if SequencesEqual(Dictionary[j], w) then
          found := j;
        Inc(j);
      end;
  Inc(CodeCount);
  SetLength(OutputCodes, CodeCount);
  OutputCodes[CodeCount - 1] := found;

  sad := TEncoding.UTF8.GetBytes(FullFlName);
  Lfn := Length(sad);
  SetLength(Result, Lfn + 2);
  //тип архивации
  Result[0] := 2;
  //длина имени, имя
  Result[1] := Lfn;
  for j := 1 to Lfn do
    Result[j+1] := sad[j-1];

  // Преобразуем массив кодов (Word) в массив байт.
  // Каждый код записывается как 2 байта (little-endian: сначала младший, затем старший).
  SetLength(Result, Length(Result) + CodeCount * 2);
  for i := 0 to CodeCount - 1 do
  begin
    temp := OutputCodes[i];
    Result[Lfn + 2 + i * 2] := Byte(temp and $FF);
    Result[Lfn + 2 + i * 2 + 1] := Byte((temp shr 8) and $FF);
  end;
end;

{---------------------------------------------------------------------------
  Функция DecompressData принимает на вход массив байт, созданный функцией LZWCompress.
  Входной массив должен состоять из 16-битных кодов, записанных в little-endian.

  Алгоритм распаковки:
  1. Инициализируется словарь из 256 записей (каждая – массив из одного байта).
  2. Первый код извлекается и по словарю определяется исходная последовательность w.
  3. Далее для каждого следующего кода:
       – Если код уже есть в словаре, извлекается соответствующая последовательность entry.
       – Если код равен значению NextCode (специальный случай), entry вычисляется как w + первый байт w.
       – В результат дописывается последовательность entry.
       – В словарь добавляется новая запись: w + первый байт entry.
       – w становится равным entry.
  4. Возвращается восстановленный массив байт.
---------------------------------------------------------------------------}
function DecompressData(const InData: TBytes): TBytes;
var
  Dictionary: array of TBytes;
  NextCode, i, CodeCount, code: Integer;
  CodeWords: TWordArray;
  w, entry: TBytes;
  OutputData: TBytes;
begin
  CodeCount := (Length(InData) - InData[1] - 2) div 2;
  SetLength(CodeWords, CodeCount);
  // Преобразуем входной массив байт в массив Word-кодов.
  for i := 0 to CodeCount - 1 do
    CodeWords[i] := InData[InData[1] + 2 + i * 2] or (InData[InData[1] + 2 + i * 2 + 1] shl 8);

  // Инициализация словаря: создаем 257 записей (каждая, кроме последней – массив с одним байтом).
  SetLength(Dictionary, 257);
  for i := 0 to 255 do
  begin
    SetLength(Dictionary[i], 1);
    Dictionary[i][0] := i;
  end;
  NextCode := 256;

  SetLength(OutputData, 0);

  // Первый код всегда есть – получаем начальную последовательность w.
  code := CodeWords[0];
  w := Dictionary[code];
  ConcatSequences(OutputData, w);

  // Обрабатываем оставшиеся коды.
  for i := 1 to High(CodeWords) do
  begin
    code := CodeWords[i];
    if code < NextCode then
      entry := Dictionary[code]
    else if code = NextCode then
    begin
      // Специальный случай: последовательность равна (w + первый байт w)
      entry := Copy(w, 0, Length(w));
      SetLength(entry, Length(entry)+1);
      entry[Length(entry)-1] := w[0];
    end;

    ConcatSequences(OutputData, entry);
  // Добавляем новую запись в словарь: w + первый байт entry.
    if NextCode < 65535 then
    begin
      SetLength(w, Length(w)+1);
      w[Length(w)-1] := entry[0];
      Dictionary[NextCode] := w;
      Inc(NextCode);
      SetLength(Dictionary, NextCode+1); // подстраиваем размер массива словаря
    end
    else
        raise Exception.Create('Выход размера словаря за 16 бит');
    w := entry;
  end;

  Result := OutputData;
end;

end.
