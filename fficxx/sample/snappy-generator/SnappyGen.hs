import Data.Monoid (mempty)
--
import FFICXX.Generate.Builder
import FFICXX.Generate.Type.Class
import FFICXX.Generate.Type.PackageInterface

snappyclasses = [ ] 

mycabal = Cabal { cabal_pkgname = "Snappy" 
                , cabal_cheaderprefix = "Snappy"
                , cabal_moduleprefix = "Snappy" }

-- myclass = Class mycabal 

-- this is standard string library
string :: Class 
string = 
  Class mycabal "string" [] mempty  (Just "CppString")
  [ 
  ]  


source :: Class 
source = 
  Class mycabal "Source" [] mempty  Nothing
  [ Virtual ulong_ "Available" []  Nothing 
  , Virtual (cstar_ CTChar) "Peek" [ star CTULong "len" ] Nothing 
  , Virtual void_ "Skip" [ ulong "n" ] Nothing
  ]


sink :: Class 
sink = 
  Class mycabal "Sink" [] mempty  Nothing
  [ Virtual void_ "Append" [ cstar CTChar "bytes", ulong "n" ] Nothing 
  , Virtual (cstar_ CTChar) "GetAppendBuffer" [ ulong "len", star CTChar "scratch" ] Nothing
  ] 

byteArraySource :: Class
byteArraySource = 
  Class mycabal "ByteArraySource" [source] mempty  Nothing
  [ Constructor [ cstar CTChar "p", ulong "n" ] Nothing 
  ] 


uncheckedByteArraySink :: Class 
uncheckedByteArraySink = 
  Class mycabal "UncheckedByteArraySink" [sink] mempty  Nothing
  [ Constructor [ star CTChar "dest" ] Nothing 
  , NonVirtual (star_ CTChar) "CurrentDestination" [] Nothing 
  ] 


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



headerMap = [ ("Sink"  , ([NS "snappy"], [HdrName "snappy-sinksource.h", HdrName "snappy.h"]))
            , ("Source", ([NS "snappy"], [HdrName "snappy-sinksource.h", HdrName "snappy.h"]))
            , ("ByteArraySource", ([NS "snappy"], [HdrName "snappy-sinksource.h", HdrName "snappy.h"]))
	    , ("UncheckedByteArraySink", ([NS "snappy"], [HdrName "snappy-sinksource.h", HdrName "snappy.h"]))
            ]

mycabalattr = 
    CabalAttr 
    { cabalattr_license = Nothing
    , cabalattr_licensefile = Nothing
    , cabalattr_extraincludedirs = []
    , cabalattr_extralibdirs = []
    }

main :: IO ()
main = do 
  simpleBuilder "Snappy" headerMap (mycabal,mycabalattr,myclasses,toplevelfunctions) [ "snappy" ]


