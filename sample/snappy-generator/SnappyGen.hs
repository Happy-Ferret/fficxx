{-# LANGUAGE ScopedTypeVariables #-}

import Data.Monoid (mempty)
import System.FilePath ((</>))
import System.Directory (getCurrentDirectory)
import           Text.StringTemplate hiding (render)
-- 
import           FFICXX.Generate.Code.Cabal
import           FFICXX.Generate.Code.Cpp
import           FFICXX.Generate.Code.Dependency
import           FFICXX.Generate.Config
import           FFICXX.Generate.Code.Cpp
import           FFICXX.Generate.Code.Dependency
import           FFICXX.Generate.Config
import           FFICXX.Generate.Generator.ContentMaker 
import           FFICXX.Generate.Generator.Driver
import           FFICXX.Generate.Type.Annotate
import           FFICXX.Generate.Type.Class
import           FFICXX.Generate.Type.PackageInterface
import           FFICXX.Generate.Util
-- 
import qualified FFICXX.Paths_fficxx as F

snappyclasses = [ ] 

mycabal = Cabal { cabal_pkgname = "Snappy" 
                , cabal_cheaderprefix = "Snappy"
                , cabal_moduleprefix = "Snappy" }

-- myclass = Class mycabal 

-- this is standard string library
string :: Class 
string = 
  Class mycabal "string" [] mempty
  [ 
  ]  
  (Just "CppString")

source :: Class 
source = 
  Class mycabal "Source" [] mempty 
  [ Virtual ulong_ "Available" []  
  , Virtual (cstar_ CTChar) "Peek" [ star CTULong "len" ] 
  , Virtual void_ "Skip" [ ulong "n" ] 
  ]
  Nothing

sink :: Class 
sink = 
  Class mycabal "Sink" [] mempty 
  [ Virtual void_ "Append" [ cstar CTChar "bytes", ulong "n" ] 
  , Virtual (cstar_ CTChar) "GetAppendBuffer" [ ulong "len", star CTChar "scratch" ] 
  ] 
  Nothing

byteArraySource :: Class
byteArraySource = 
  Class mycabal "ByteArraySource" [source] mempty 
  [ Constructor [ cstar CTChar "p", ulong "n" ] 
  ] 
  Nothing

uncheckedByteArraySink :: Class 
uncheckedByteArraySink = 
  Class mycabal "UncheckedByteArraySink" [sink] mempty
  [ Constructor [ star CTChar "dest" ]
  , NonVirtual (star_ CTChar) "CurrentDestination" [] 
  ] 
  Nothing

myclasses = [ source, sink, byteArraySource, uncheckedByteArraySink, string ] 

toplevelfunctions =
  [ TopLevelFunction ulong_ "Compress" [cppclass source "src", cppclass sink "snk"] Nothing   
  , TopLevelFunction bool_ "GetUncompressedLength" [cppclass source "src", star CTUInt "result"] Nothing 
  , TopLevelFunction ulong_ "Compress" [cstar CTChar "input", ulong "input_length", cppclass string "output"] (Just "compress_1")
  , TopLevelFunction bool_ "Uncompress" [cstar CTChar "compressed", ulong "compressed_length", cppclass string "uncompressed"] Nothing 
  , TopLevelFunction void_ "RawCompress" [cstar CTChar "input", ulong "input_length", star CTChar "compresseed", star CTULong "compressed_length" ] Nothing
  , TopLevelFunction bool_ "RawUncompress" [cstar CTChar "compressed", ulong "compressed_length", star CTChar "uncompressed"] Nothing 
  , TopLevelFunction bool_ "RawUncompress" [cppclass source "src", star CTChar "uncompressed"] (Just "rawUncompress_1")
  , TopLevelFunction ulong_ "MaxCompressedLength" [ ulong "source_bytes" ] Nothing
  , TopLevelFunction bool_ "GetUncompressedLength" [ cstar CTChar "compressed", ulong "compressed_length", star CTULong "result" ] (Just "getUncompressedLength_1")
  , TopLevelFunction bool_ "IsValidCompressedBuffer" [ cstar CTChar "compressed", ulong "compressed_length" ] Nothing 
  ]  

-- | 
cabalTemplate :: String 
cabalTemplate = "Pkg.cabal"


-- | 
mkCabalFile :: FFICXXConfig
            -> STGroup String  
            -> (TopLevelImportHeader,[ClassModule])
            -> FilePath  
            -> IO () 
mkCabalFile config templates (tih,classmodules) cabalfile = do 
  cpath <- getCurrentDirectory 
 
  let str = renderTemplateGroup 
              templates 
              [ ("pkgname", "Snappy") 
              , ("version",  "0.0") 
              , ("license", "" ) 
              , ("buildtype", "Simple")
              , ("deps", "" ) 
              , ("csrcFiles", genCsrcFiles (tih,classmodules))
              , ("includeFiles", genIncludeFiles "Snappy" classmodules) 
              , ("cppFiles", genCppFiles (tih,classmodules))
              , ("exposedModules", genExposedModules "Snappy" classmodules) 
              , ("otherModules", genOtherModules classmodules)
              , ("extralibdirs", "" )  
              , ("extraincludedirs", "" )  
              , ("extralib", ", snappy")
              , ("cabalIndentation", cabalIndentation)
              ]
              cabalTemplate 
  writeFile cabalfile str




main :: IO ()
main = do 
  putStrLn "generate snappy" 
  cwd <- getCurrentDirectory 

  let cfg =  FFICXXConfig { fficxxconfig_scriptBaseDir = cwd 
                          , fficxxconfig_workingDir = cwd </> "working"
                          , fficxxconfig_installBaseDir = cwd </> "Snappy"  
                          } 
      workingDir = fficxxconfig_workingDir cfg
      installDir = fficxxconfig_installBaseDir cfg 
      pkgname = "Snappy" 
      (mods,cihs,tih) = mkAll_ClassModules_CIH_TIH 
                          ("Snappy", (const ([NS "snappy"],["snappy-sinksource.h","snappy.h"]))) 
                          (myclasses, toplevelfunctions)
      hsbootlst = mkHSBOOTCandidateList mods 
      cglobal = mkGlobal myclasses 
      summarymodule = "Snappy" 
      cabalFileName = "Snappy.cabal"
  templateDir <- F.getDataDir >>= return . (</> "template")
  (templates :: STGroup String) <- directoryGroup templateDir 
  -- 
  notExistThenCreate workingDir
  notExistThenCreate installDir 
  notExistThenCreate (installDir </> "src") 
  notExistThenCreate (installDir </> "csrc")
  -- 
  putStrLn "cabal file generation" 
  mkCabalFile cfg templates (tih,mods) (workingDir </> cabalFileName)
  -- 
  putStrLn "header file generation"
  let typmacro = TypMcro "__SNAPPY__"
  writeTypeDeclHeaders templates workingDir typmacro pkgname cihs
  mapM_ (writeDeclHeaders templates workingDir typmacro pkgname) cihs
  writeTopLevelFunctionHeaders templates workingDir typmacro pkgname tih
  -- 
  putStrLn "cpp file generation" 
  mapM_ (writeCppDef templates workingDir) cihs
  writeTopLevelFunctionCppDef templates workingDir typmacro pkgname tih
  -- 
  putStrLn "RawType.hs file generation" 
  mapM_ (writeRawTypeHs templates workingDir) mods 
  -- 
  putStrLn "FFI.hsc file generation"
  mapM_ (writeFFIHsc templates workingDir) mods
  -- 
  putStrLn "Interface.hs file generation" 
  mapM_ (writeInterfaceHs mempty templates workingDir) mods
  -- 
  putStrLn "Cast.hs file generation"
  mapM_ (writeCastHs templates workingDir) mods
  -- 
  putStrLn "Implementation.hs file generation"
  mapM_ (writeImplementationHs mempty templates workingDir) mods
  -- 
  putStrLn "hs-boot file generation" 
  mapM_ (writeInterfaceHSBOOT templates workingDir) hsbootlst  
  -- 
  putStrLn "module file generation" 
  mapM_ (writeModuleHs templates workingDir) mods
  -- 
  putStrLn "summary module generation generation"
  writePkgHs summarymodule templates workingDir mods tih
  -- 
  putStrLn "copying"
  copyFileWithMD5Check (workingDir </> cabalFileName)  (installDir </> cabalFileName) 
  -- copyPredefined templateDir (srcDir ibase) pkgname
  copyCppFiles workingDir (csrcDir installDir) pkgname (tih,cihs)
  mapM_ (copyModule workingDir (srcDir installDir) summarymodule) mods 


