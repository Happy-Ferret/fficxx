Name:		$pkgname$
Version:	$version$
Synopsis:	$synopsis$
Description: 	$description$
Homepage:       $homepage$
$licenseField$
$licenseFileField$
Author:		$author$
Maintainer: 	$maintainer$
Category:       $category$
Tested-with:    GHC >= 7.6
Build-Type: 	$buildtype$
cabal-version:  >=1.10
Extra-source-files:
$cabalIndentation$CHANGES
$cabalIndentation$Config.hs
$csrcFiles$

$sourcerepository$

Library
  default-language: Haskell2010
  hs-source-dirs: src
  ghc-options:  -Wall -funbox-strict-fields -fno-warn-unused-do-bind -fno-warn-orphans -fno-warn-unused-imports
  ghc-prof-options: -caf-all -auto-all
  cc-options: $ccOptions$
  Build-Depends:      base>4 && < 5, fficxx-runtime >= 0.2 $deps$
  Exposed-Modules:
$exposedModules$
  Other-Modules:
$otherModules$
  extra-lib-dirs: $extralibdirs$
  extra-libraries:    stdc++ $extraLibraries$
  Include-dirs:       csrc $extraincludedirs$
  Install-includes:
$includeFiles$
  C-sources:
$cppFiles$




