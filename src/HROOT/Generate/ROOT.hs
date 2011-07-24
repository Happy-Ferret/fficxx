module HROOT.Generate.ROOT where

import HROOT.Generate.CType
import HROOT.Generate.Function
import HROOT.Generate.Class

tObject :: Class
tObject = Class "TObject" [] 
          [ Function cstring_ "GetName" [] Ordinary
          , Function void_    "Draw"    [cstring "option"] Ordinary
          , Function void_   "SaveAs"          [cstring "filename", cstring "option"] Ordinary
          , Function int_     "Write"   [cstring "name", int "option", int "bufsize" ] Ordinary
          ]


tNamed :: Class
tNamed = Class "TNamed" [tObject] 
         [ Function void_   "SetTitle"        [cstring "name"] Ordinary 
         ]


tFormula :: Class
tFormula = Class "TFormula" [] 
           [ Function double_ "GetParameter"    [int "idx" ] Ordinary
           , Function void_   "SetParameter"    [int "idx" , double "value"] Ordinary
           ]

tAttLine :: Class
tAttLine = Class "TAttLine" [] 
           [ Function void_   "SetLineColor"    [int "color" ] Ordinary
           ] 

tAttFill :: Class
tAttFill = Class "TAttFill" [] 
           [ Function void_   "SetFillColor"    [int "color" ] Ordinary
           , Function void_   "SetFillStyle"    [int "style" ] Ordinary 
           ]

tAttMarker :: Class
tAttMarker = Class "TAttMarker" [] 
             [ ]  


tWbox :: Class
tWbox    = Class "TWbox" [] 
                 [ Function void_   "SetBorderMode"   [int "bordermode" ] Ordinary
                 ] 

tAttAxis :: Class
tAttAxis = Class "TAttAxis" [] 
                 [ Function void_   "SetLabelColor"   [int    "color" ] Ordinary
                 , Function void_   "SetLabelSize"    [double "size"  ] Ordinary
                 , Function void_   "SetTickLength"   [double "length" ] Ordinary
                 , Function void_   "SetTitleOffset"  [double "offset" ] Ordinary
                 , Function void_   "SetNdivisions"   [int "n", bool "optim" ] Ordinary
                 ] 
 

tHStack :: Class
tHStack = Class "THStack" [tNamed] 
          [ Function self_ "New" [cstring "name",cstring "title"]  Constructor
          ] 


tAttPad :: Class
tAttPad = Class "TAttPad" []
          []


tF1 :: Class
tF1 = Class "TF1" [tFormula, tAttLine, tAttFill] 
      [ Function self_ "New" [cstring "name",cstring "formula",double "xmin",double "xmax"] Constructor
      ]

tGraph :: Class
tGraph = Class "TGraph" [tNamed, tAttLine, tAttFill, tAttMarker] 
         [ Function self_ "New" [int "n", doublep "x", doublep "y"] Constructor
         ]

tAxis :: Class
tAxis = Class "TAxis" [tNamed, tAttAxis] 
        []
 
tLine :: Class
tLine = Class "TLine" [tObject, tAttLine] 
        [ Function self_ "New" [double "x1", double "y1", double "x2", double "y2" ] Ordinary
        ]            
           
tText :: Class
tText = Class "TText" [tNamed, tAttText]
        [] 

tAttText :: Class
tAttText = Class "TAttText" [] 
           [ Function void_ "SetTextColor" [int "tcolor"] Ordinary 
           , Function void_ "SetTextAlign" [int "align"] Ordinary 
           , Function void_ "SetTextSize"  [double "tsize"] Ordinary 
           ]  

tLatex :: Class
tLatex = Class "TLatex" [tText, tAttLine] 
         [ Function self_ "New"       [double "x", double "y", cstring "text"] Constructor
         , Function self_ "DrawLatex" [double "x", double "y", cstring "text"] (NonVirtual "drawLatex")
         ]


tDirectory :: Class
tDirectory = Class "TDirectory" [tNamed] 
             [ Function void_ "Close"    [ cstring "option" ] Ordinary ]

tDirectoryFile :: Class
tDirectoryFile = Class "TDirectoryFile" [tDirectory] 
                 []

tFile :: Class
tFile = Class "TFile" [tDirectoryFile] 
        [ Function self_ "New" [cstring "fname", cstring "option", cstring "ftitle", int "compress" ] Constructor
        ]

tTree :: Class 
tTree = Class "TTree" [tNamed, tAttLine, tAttFill, tAttMarker]
        []

tBranch :: Class
tBranch = Class "TBranch" [tNamed, tAttFill]
          []

tVirtualTreePlayer :: Class
tVirtualTreePlayer = Class "TVirtualTreePlayer" [tObject]
                     []

tTreePlayer :: Class
tTreePlayer = Class "TTreePlayer" [tVirtualTreePlayer] 
              []
                 

tAtt3D :: Class
tAtt3D = Class "TAtt3D" []
         []


tArray :: Class
tArray = Class "TArray" [] 
         []

tArrayC :: Class 
tArrayC = Class "TArrayC" [tArray]
          []

tArrayD :: Class
tArrayD = Class "TArrayD" [tArray]
          []

tArrayF :: Class 
tArrayF = Class "TArrayF" [tArray]
          []

tArrayI :: Class
tArrayI = Class "TArrayI" [tArray]
          []

tArrayL :: Class
tArrayL = Class "TArrayL" [tArray]
          []

tArrayL64 :: Class
tArrayL64 = Class "TArrayL64" [tArray]
            []

tArrayS :: Class
tArrayS = Class "TArrayS" [tArray]
          []

tH1 :: Class
tH1 = Class "TH1" [tNamed, tAttLine, tAttFill, tAttMarker] 
      [ Function (cppclass "TAxis") "GetXaxis" [] Ordinary
      , Function (cppclass "TAxis") "GetYaxis" [] Ordinary
      , Function (cppclass "TAxis") "GetZaxis" [] Ordinary
      , Function void_ "Add" [ (CPT (CPTClass "TH1") NoConst, "h1"), double "c1" ] Ordinary 
      , Function int_  "Fill" [double "x"] (Alias "fill1")
      ] 

tH2 :: Class 
tH2 = Class "TH2" [tH1] 
      [ Function int_ "Fill" [double "x", double "y"] (Alias "fill2") 
      ]


tH3 :: Class
tH3 = Class "TH3" [tH1, tAtt3D]
      []


tH1C :: Class 
tH1C = Class "TH1C" [tH1, tArrayC]
       []
 
tH1D :: Class
tH1D = Class "TH1D" [tH1, tArrayD]
       []

tH1F :: Class
tH1F = Class "TH1F" [tH1, tArrayF] 
       [ Function self_ "New" [cstring "name",cstring "title",int "nbinsx",double "xlow",double "xup"] Constructor
       ] 
           
tH1I :: Class 
tH1I = Class "TH1I" [tH1, tArrayI]
       []

tH1K :: Class
tH1K = Class "TH1K" [tH1, tArrayF]
       []

tH1S :: Class
tH1S = Class "TH1S" [tH1, tArrayS]
       []

tH2C :: Class
tH2C = Class "TH2C" [tH2, tArrayC]
       []

tH2D :: Class 
tH2D = Class "TH2D" [tH2, tArrayD] 
       []

tH2F :: Class
tH2F = Class "TH2F" [tH2, tArrayF] 
       [ Function self_ "New" [cstring "name",cstring "title",int "nbinsx",double "xlow",double "xup"
                              ,int "nbinsy", double "ylow", double "yup"] Constructor
       ]

tH2I :: Class
tH2I = Class "TH2I" [tH2, tArrayI]
       []

tH2Poly :: Class 
tH2Poly = Class "TH2Poly" [tH2]
          []

tH2S :: Class
tH2S = Class "TH2S" [tH2, tArrayS]
       []



tH3C :: Class 
tH3C = Class "TH3C" [tH3, tArrayC]
       []

tH3D :: Class
tH3D = Class "TH3D" [tH3, tArrayD] 
       []

tH3F :: Class
tH3F = Class "TH3F" [tH3, tArrayF]
       []

tH3I :: Class
tH3I = Class "TH3I" [tH3, tArrayI]
       []

tH3S :: Class
tH3S = Class "TH3S" [tH3, tArrayS]
       []


tQObject :: Class
tQObject = Class "TQObject" [] 
           []

tVirtualPad :: Class
tVirtualPad = Class "TVirtualPad" [tObject, tAttLine, tAttFill, tAttPad, tQObject]
              [] 

tPad :: Class 
tPad = Class "TPad" [tVirtualPad] 
       []
 
tButton :: Class
tButton = Class "TButton" [tPad, tAttText]
          []

tGroupButton :: Class
tGroupButton = Class "TGroupButton" [tButton]
               []

tCanvas :: Class
tCanvas = Class "TCanvas" [tPad] 
          [ Function self_ "New" [cstring "name",cstring "title",int "ww",int "wh"] Constructor
          ] 

{- tDialogCanvas :: Class
tDialogCanvas = Class "TDialogCanvas" [tCanvas, tAttText]
                 []

tInspectCanvas :: Class
tInspectCanvas = Class "TInspectCanvas" [tCanvas, tAttText]
                 [] -}

tEvePad :: Class
tEvePad = Class "TEvePad" [tPad]
          []

tSlider :: Class 
tSlider = Class "TSlider" [tPad]
          []


tApplication :: Class
tApplication = Class "TApplication" [tObject] 
               [ Function self_ "New"    [ cstring "appClassName", intp "argc", charpp "argv"  ] Constructor
               , Function void_ "Run"    [] Ordinary  
               ]


root_all_classes :: [Class]
root_all_classes = 
  [ tObject, tNamed, tFormula
  , tAttLine, tAttFill, tAttAxis, tAttText, tAtt3D, tAttMarker
  , tAttPad
  , tHStack, tF1, tGraph
  , tAxis, tLatex, tText
  , tDirectory, tDirectoryFile, tFile
  , tTree, tBranch, tVirtualTreePlayer, tTreePlayer
  , tArray, tArrayC, tArrayD, tArrayF, tArrayI, tArrayL, tArrayL64
  , tArrayS
  , tH1, tH2, tH3
  , tH1C, tH1D, tH1F, tH1I, tH1S
  , tH2C, tH2D, tH2F, tH2I, tH2Poly, tH2S 
  , tH3C, tH3D, tH3F, tH3I, tH3S  
  , tQObject
  , tVirtualPad, tPad, tButton, tGroupButton, tCanvas
--  , tDialogCanvas, tInspectCanvas
  , tEvePad, tSlider
  , tApplication
-- , tWbox, tLine , tApplication, 
  ]










