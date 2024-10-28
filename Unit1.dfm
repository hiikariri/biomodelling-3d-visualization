object Form1: TForm1
  Left = 605
  Top = 200
  Width = 928
  Height = 518
  Caption = '3D Modelling'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object grp1: TGroupBox
    Left = 8
    Top = 8
    Width = 393
    Height = 369
    Caption = 'Control Panel'
    TabOrder = 0
    object GroupBox1: TGroupBox
      Left = 130
      Top = 240
      Width = 121
      Height = 105
      Caption = 'Angle Control'
      TabOrder = 0
      object Label1: TLabel
        Left = 8
        Top = 24
        Width = 27
        Height = 13
        Caption = 'Pitch:'
      end
      object Label2: TLabel
        Left = 8
        Top = 48
        Width = 24
        Height = 13
        Caption = 'Yaw:'
      end
      object Label3: TLabel
        Left = 8
        Top = 76
        Width = 21
        Height = 13
        Caption = 'Roll:'
      end
      object se1: TSpinEdit
        Left = 40
        Top = 24
        Width = 73
        Height = 22
        MaxValue = 0
        MinValue = 0
        TabOrder = 0
        Value = 0
        OnChange = se1Change
      end
      object se2: TSpinEdit
        Left = 40
        Top = 48
        Width = 73
        Height = 22
        MaxValue = 0
        MinValue = 0
        TabOrder = 1
        Value = 0
        OnChange = se2Change
      end
      object se3: TSpinEdit
        Left = 40
        Top = 72
        Width = 73
        Height = 22
        MaxValue = 0
        MinValue = 0
        TabOrder = 2
        Value = 0
        OnChange = se3Change
      end
    end
    object cht1: TChart
      Left = 24
      Top = 16
      Width = 360
      Height = 217
      BackWall.Brush.Color = clWhite
      BackWall.Brush.Style = bsClear
      Title.Text.Strings = (
        'TChart')
      BottomAxis.Title.Caption = 'Time (Seconds)'
      RightAxis.Title.Caption = 'Angle (Degrees)'
      View3D = False
      TabOrder = 1
      object lnsrsSeries1: TLineSeries
        Marks.ArrowLength = 8
        Marks.Callout.Brush.Color = clBlack
        Marks.Callout.Length = 8
        Marks.Visible = False
        SeriesColor = clRed
        Title = 'Rot. Angle Up'
        Pointer.InflateMargins = True
        Pointer.Style = psRectangle
        Pointer.Visible = False
        XValues.Name = 'X'
        XValues.Order = loAscending
        YValues.Name = 'Y'
      end
      object lnsrsSeries2: TLineSeries
        Marks.ArrowLength = 8
        Marks.Callout.Brush.Color = clBlack
        Marks.Callout.Length = 8
        Marks.Visible = False
        SeriesColor = clBlue
        Title = 'Rot. Angle Low'
        Pointer.InflateMargins = True
        Pointer.Style = psRectangle
        Pointer.Visible = False
        XValues.Name = 'X'
        XValues.Order = loAscending
        YValues.Name = 'Y'
      end
    end
    object btn3: TBitBtn
      Left = 24
      Top = 320
      Width = 97
      Height = 33
      TabOrder = 2
      Kind = bkClose
    end
    object btn2: TButton
      Left = 24
      Top = 280
      Width = 97
      Height = 33
      Caption = 'Stop'
      TabOrder = 3
      OnClick = btn2Click
    end
    object btn1: TButton
      Left = 24
      Top = 240
      Width = 97
      Height = 33
      Caption = 'Start'
      TabOrder = 4
      OnClick = btn1Click
    end
    object rb1: TRadioButton
      Left = 264
      Top = 248
      Width = 113
      Height = 17
      Caption = 'Upper limb'
      TabOrder = 5
    end
    object rb2: TRadioButton
      Left = 264
      Top = 272
      Width = 113
      Height = 17
      Caption = 'Two upper'
      TabOrder = 6
    end
    object rb3: TRadioButton
      Left = 264
      Top = 296
      Width = 113
      Height = 17
      Caption = 'Cylinder'
      TabOrder = 7
    end
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 1
    OnTimer = Timer1Timer
    Left = 272
    Top = 328
  end
  object Timer2: TTimer
    Interval = 1
    OnTimer = Timer2Timer
    Left = 312
    Top = 328
  end
  object Timer3: TTimer
    Enabled = False
    Interval = 1
    Left = 352
    Top = 328
  end
end
