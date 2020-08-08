//example script
{$loadlib example.dll}
var
data,s: string;
begin
 Data := GetData();
 WriteLn('Recieved: ' + Data);
 s := Compress(Data);
 WriteLn(s);
 StrToFile(WorkingDirectory + '/data/' + 'Compress.txt',s);
 WriteLn('Recovered: ' + Decompress(FileToStr(WorkingDirectory + '/data/' + 'Compress.txt')));
 //SetData(Data);
 
end.