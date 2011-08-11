module HROOT.Generate.Code.HsFrontEnd where

import qualified Data.Map as M

import HROOT.Generate.Type.CType
import HROOT.Generate.Type.Method
import HROOT.Generate.Type.Class

import HROOT.Generate.Util


import Control.Monad.State
----------------

genHsFrontDecl :: Class -> String 
genHsFrontDecl c =  
  let header = render hsClassDeclHeaderTmpl [ ("classname", typeclassName c ) ] 
      bodyline func = render hsClassDeclFuncTmpl 
                                    [ ("funcname", hsFuncName c func) 
                                    , ("args" , prefixstr func ++ argstr func ) 
                                    ] 
      prefixstr func =  
        let prefixlst = (snd . mkHsFuncArgType c . genericFuncArgs) func
                        ++ (snd . mkHsFuncRetType c ) func
        in  if null prefixlst
              then "" 
              else "(" ++ (intercalateWith conncomma id prefixlst) ++ ") => "  
                  
      argstr func = intercalateWith connArrow id $
                      [ "a" ] 
                      ++ fst (mkHsFuncArgType c (genericFuncArgs func))
                      ++ ["IO " ++ fst (mkHsFuncRetType c func)]  
      bodylines = map bodyline . virtualFuncs 
                      $ (class_funcs c) 
  in  intercalateWith connRet id (header : bodylines) 



genAllHsFrontDecl :: [Class] -> String 
genAllHsFrontDecl = intercalateWith connRet2 genHsFrontDecl


genHsFrontInst :: Class -> Class -> String 
genHsFrontInst parent child  
  | (not.isAbstractClass) child = 
    let headline = "instance " ++ typeclassName parent ++ " " ++ class_name child ++ " where" 
        defline func = "  " ++ hsFuncName child func ++ " = " ++ hsFuncXformer func ++ " " ++ hscFuncName child func 
        deflines = (map defline) . virtualFuncs . class_funcs $ parent 
    in  intercalateWith connRet id (headline : deflines) 
  | otherwise = ""
   
genAllHsFrontInst :: [Class] -> DaughterMap -> String 
genAllHsFrontInst cs m = 
  let selflst = map (\x->(x,[x])) cs 
      lst = selflst ++ M.toList m  
      f (x,ys) = intercalateWith connRet (genHsFrontInst x) ys
  in  intercalateWith connRet2 f lst
      
genHsFrontInstNew :: Class         -- ^ only concrete class 
                    -> String 
genHsFrontInstNew c = 
  if null newfuncs 
  then ""
  else let newfunc = head newfuncs
           newlinehead = "new" ++ class_name c ++ " :: " ++ argstr newfunc 
           newlinebody = "new" ++ class_name c ++ " = " ++ hsFuncXformerNew newfunc ++ " " ++ hscFuncName c newfunc 
           argstr func = intercalateWith connArrow id $
                           map (ctypeToHsType c.fst) (genericFuncArgs func)
                           ++ ["IO " ++ (ctypeToHsType c.genericFuncRet) func]
           newline = newlinehead ++ "\n" ++ newlinebody 
       in newline
  where newfuncs = filter isNewFunc (class_funcs c)  

genAllHsFrontInstNew :: [Class]    -- ^ only concrete class 
                     -> String 
genAllHsFrontInstNew = intercalateWith connRet2 genHsFrontInstNew 


genHsFrontInstNonVirtual :: Class -> String 
genHsFrontInstNonVirtual c 
  | (not.null) nonvirtualFuncs  =                        
    let header f = (aliasedFuncName c f) ++ " :: " ++ argstr f
        body f  = (aliasedFuncName c f)  ++ " = " ++ hsFuncXformer f ++ " " ++ hscFuncName c f 
        argstr func = intercalateWith connArrow id $ 
                        [class_name c]  
                        ++ map (ctypeToHsType c.fst) (genericFuncArgs func)
                        ++ ["IO " ++ (ctypeToHsType c . genericFuncRet) func] 
    in  intercalateWith connRet (\f -> header f ++ "\n" ++ body f) nonvirtualFuncs
  | otherwise = ""   
 where nonvirtualFuncs = nonVirtualNotNewFuncs (class_funcs c)

genAllHsFrontInstNonVirtual :: [Class] -> String 
genAllHsFrontInstNonVirtual = intercalateWith connRet genHsFrontInstNonVirtual

genHsFrontInstCastable :: Class -> String 
genHsFrontInstCastable c 
  | (not.isAbstractClass) c = 
    let iname = typeclassName c
        (_,rname) = hsClassName c
    in  render hsInterfaceCastableInstanceTmpl 
               [("interfaceName",iname),("rawClassName",rname)]
  | otherwise = "" 

genAllHsFrontInstCastable :: [Class] -> String 
genAllHsFrontInstCastable = 
  intercalateWith connRet2 genHsFrontInstCastable



--------------------------

rawToHighDecl :: String
rawToHighDecl = "data $rawname$\nnewtype $highname$ = $highname$ (ForeignPtr $rawname$) deriving (Eq, Ord, Show)"

rawToHighInstance :: String
rawToHighInstance = "instance FPtr $highname$ where\n   type Raw $highname$ = $rawname$\n   get_fptr ($highname$ fptr) = fptr\n   cast_fptr_to_obj = $highname$"


hsClassType :: Class -> String 
hsClassType c = let decl = render rawToHighDecl tmplName
                    inst1 = render rawToHighInstance tmplName
                in  decl `connRet` inst1 
  where (highname,rawname) = hsClassName c
        tmplName = [("rawname",rawname),("highname",highname)] 
            
mkRawClasses :: [Class] -> String 
mkRawClasses = intercalateWith connRet2 hsClassType


hsClassDeclHeaderTmpl :: String
hsClassDeclHeaderTmpl = "class $classname$ a where"

hsClassDeclFuncTmpl :: String
hsClassDeclFuncTmpl = "    $funcname$ :: $args$ "


hsArgs :: Class -> Args -> String
hsArgs c = intercalateWith connArrow (ctypeToHsType c. fst) 

mkHsFuncArgType :: Class -> Args -> ([String],[String]) 
mkHsFuncArgType c lst = 
  let  (args,st) = runState (mapM mkFuncArgTypeWorker lst) ([],(0 :: Int))
  in   (args,fst st)
  where mkFuncArgTypeWorker (typ,_var) = 
          case typ of                  
            SelfType -> return "a"
            CT _ _   -> return $ ctypeToHsType c typ 
            CPT (CPTClass cname) _ -> do 
              (prefix,n) <- get 
              let iname = typeclassNameFromStr cname -- typeclassName c
                  newname = 'c' : show n
                  newprefix1 = iname ++ " " ++ newname    
                  newprefix2 = "FPtr " ++ newname
              put (newprefix1:newprefix2:prefix,n+1)
              return newname
            _ -> error ("No such c type : " ++ show typ)  

mkHsFuncRetType :: Class -> Function -> (String,[String])
mkHsFuncRetType c func = 
  let rtyp = genericFuncRet func
  in case rtyp of 
    SelfType -> ("a",[])
    CPT (CPTClass cname) _ ->  
      let iname = typeclassNameFromStr cname -- typeclassName c
          newname = "b"
          newprefix1 = iname ++ " " ++ newname    
          newprefix2 = "FPtr " ++ newname
      in  ("b",[newprefix1,newprefix2])
    _ -> (ctypeToHsType c rtyp,[])

      
----------                        

hsInterfaceCastableInstanceTmpl :: String 
hsInterfaceCastableInstanceTmpl = 
  "instance ($interfaceName$ a, FPtr a) => Castable a (Ptr $rawClassName$) where\n  cast = unsafeForeignPtrToPtr . castForeignPtr . get_fptr\n  uncast = cast_fptr_to_obj . castForeignPtr . unsafePerformIO . newForeignPtr_ \n"




----------
