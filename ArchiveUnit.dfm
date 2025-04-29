object ArchiveForm: TArchiveForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  Caption = 'Archive'
  ClientHeight = 190
  ClientWidth = 585
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  TextHeight = 15
  object Label1: TLabel
    Left = 8
    Top = 3
    Width = 95
    Height = 15
    Caption = 'Archive file name:'
  end
  object editFileName: TEdit
    Left = 8
    Top = 24
    Width = 481
    Height = 23
    TabOrder = 0
    OnChange = editFileNameChange
  end
  object chooseFileButton: TButton
    Left = 495
    Top = 24
    Width = 82
    Height = 25
    Caption = 'Choose file...'
    TabOrder = 1
    OnClick = chooseFileButtonClick
  end
  object archiveButton: TButton
    Left = 421
    Top = 159
    Width = 75
    Height = 25
    Caption = 'Archive'
    Enabled = False
    TabOrder = 3
    OnClick = archiveButtonClick
  end
  object cancelButton: TButton
    Left = 502
    Top = 159
    Width = 75
    Height = 25
    Caption = 'Cancel'
    TabOrder = 4
    OnClick = cancelButtonClick
  end
  object AlgorithmGroupBox: TGroupBox
    Left = 8
    Top = 53
    Width = 569
    Height = 100
    Caption = 'Archiving algorithm'
    TabOrder = 2
    object Algorithm1: TRadioButton
      Left = 16
      Top = 25
      Width = 113
      Height = 17
      Caption = 'Huffman'
      Checked = True
      TabOrder = 0
      TabStop = True
    end
    object Algorithm2: TRadioButton
      Left = 16
      Top = 48
      Width = 113
      Height = 17
      Caption = 'LZ77'
      TabOrder = 1
    end
    object Algorithm3: TRadioButton
      Left = 16
      Top = 71
      Width = 113
      Height = 17
      Caption = 'LZW'
      TabOrder = 2
    end
  end
  object fileSaveDialog: TSaveDialog
    Left = 552
    Top = 56
  end
end
