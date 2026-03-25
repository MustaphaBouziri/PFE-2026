codeunit 50120 "MES Json Helper"
{
    Access = Internal;

    procedure JsonToText(J: JsonObject): Text
    var
        JsonText: Text;
    begin
        J.WriteTo(JsonText);
        exit(JsonText);
    end;

    procedure JsonToTextArr(J: JsonArray): Text
    var
        JsonText: Text;
    begin
        J.WriteTo(JsonText);
        exit(JsonText);
    end;

    procedure BuildError(ErrorCode: Text; Message: Text): Text
    var
        ErrJ: JsonObject;
    begin
        ErrJ.Add('success', false);
        ErrJ.Add('error', ErrorCode);
        ErrJ.Add('message', Message);
        exit(JsonToText(ErrJ));
    end;

    procedure BuildErrorFromLastError(ErrorCode: Text): Text
    var
        Msg: Text;
    begin
        Msg := GetLastErrorText();
        ClearLastError();
        exit(BuildError(ErrorCode, Msg));
    end;
}
