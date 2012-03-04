{-# LANGUAGE DeriveDataTypeable #-}

module Development.NSIS.Type where

import Data.Data

class Default a where def :: a
instance Default (Maybe a) where def = Nothing
instance Default [a] where def = []


newtype Var = Var Int deriving (Data,Typeable,Eq)
instance Default Var where def = Var 0
instance Show Var where show (Var i) = "$_" ++ show i


-- | A code label, used for @goto@ programming, see 'Development.NSIS.Sugar.newLabel'.
newtype Label = Label Int deriving (Data,Typeable,Eq)
instance Show Label where show (Label i) = if i == 0 then "0" else "_lbl" ++ show i


newtype Fun = Fun Int deriving (Data,Typeable)
instance Show Fun where show (Fun i) = "_fun" ++ show i


newtype SectionId = SectionId Int deriving (Data,Typeable)
instance Show SectionId where show (SectionId i) = "${_sec" ++ show i ++ "}"


type Val = [Val_]
data Val_ = Var_ Var | Builtin String | Literal String deriving (Data,Typeable,Eq)

instance Show Val_ where
    show x = show [x]
    showList xs = showString $ "\"" ++ concatMap f xs ++ "\""
        where
            f (Var_ x) = show x
            f (Builtin x) = "$" ++ x
            f (Literal x) = concatMap g x

            g '\"' = "$\\\""
            g '\r' = "$\\r"
            g '\n' = "$\\n"
            g '\t' = "$\\t"
            g '$' = "$$"
            g x = [x]


data NSIS
      -- primitives
    = Assign Var Val
    | Goto Label
    | Labeled Label

      -- functions and branches
    | StrCmpS Val Val Label Label
    | IntCmp Val Val Label Label Label
    | IntOp Var Val String Val
    | StrCpy Var Val Val Val
    | StrLen Var Val
    | GetFileTime Val Var Var
    | IfErrors Label Label
    | SectionGetText SectionId Var
    | SectionSetText SectionId Val
    | IfFileExists Val Label Label
    | FindFirst Var Var Val
    | FindNext Val Var
    | FindClose Val

      -- blocks
    | Section ASection [NSIS]
    | SectionGroup ASectionGroup [NSIS]
    | Function Fun [NSIS]
    | Call Fun

      -- Global settings
    | Name Val
    | File AFile
    | OutFile Val
    | InstallDir Val
    | InstallIcon Val
    | UninstallIcon Val
    | HeaderImage (Maybe Val)
    | Page Page
    | Unpage Page

      -- Actions
    | SetOutPath Val
    | CreateDirectory Val
    | SetCompressor ACompressor
    | WriteUninstaller Val
    | FileOpen Var Val FileMode
    | FileWrite Val Val
    | FileClose Val
    | MessageBox [MessageBoxType] Val [(String,Label)]
    | CreateShortcut AShortcut
    | WriteRegStr HKEY Val Val Val
    | WriteRegDWORD HKEY Val Val Val
    | ReadRegStr Var HKEY Val Val
    | DeleteRegKey HKEY Val
    | Exec Val
    | ClearErrors
    | Delete ADelete
    | RMDir ARMDir
    | RequestExecutionLevel Level
    | InstallDirRegKey HKEY Val Val
    | AllowRootDirInstall Bool
    | Caption Val
    | ShowInstDetails Visibility
    | ShowUninstDetails Visibility
    | DetailPrint Val
      deriving (Data,Typeable,Show)

-- | Mode to use with 'Development.
data FileMode
    = ModeRead -- ^ Read a file.
    | ModeWrite -- All contents of file are destroyed.
    | ModeAppend -- ^ Opened for both read and write, contents preserved.
     deriving (Data,Typeable,Bounded,Enum,Eq,Ord)
    
instance Show FileMode where
    show ModeRead = "r"
    show ModeWrite = "w"
    show ModeAppend = "a"


data AShortcut = AShortcut
    {scFile :: Val
    ,scTarget :: Val
    ,scParameters :: Val
    ,scIconFile :: Val
    ,scIconIndex :: Val
    ,scStartOptions :: String
    ,scKeyboardShortcut :: String
    ,scDescription :: Val
    } deriving (Data,Typeable,Show)

instance Default AShortcut where def = AShortcut def def def def def def def def

data ASection = ASection
    {secId :: SectionId
    ,secName :: Val
    ,secDescription :: Val
    ,secBold :: Bool
    ,secRequired :: Bool
    ,secUnselected :: Bool
    } deriving (Data,Typeable,Show)

instance Default ASection where def = ASection (SectionId 0) def def False False False

data ASectionGroup = ASectionGroup
    {secgId :: SectionId
    ,secgName :: Val
    ,secgExpanded :: Bool
    ,secgDescription :: Val
    } deriving (Data,Typeable,Show)

instance Default ASectionGroup where def = ASectionGroup (SectionId 0) def False def

data Compressor = LZMA | ZLIB | BZIP2 deriving (Data,Typeable,Show)

instance Default Compressor where def = ZLIB

data ACompressor = ACompressor 
    {compType :: Compressor
    ,compSolid :: Bool
    ,compFinal :: Bool
    } deriving (Data,Typeable,Show)

instance Default ACompressor where def = ACompressor def False False

data AFile = AFile
    {filePath :: Val
    ,fileNonFatal :: Bool
    ,fileRecursive :: Bool
    } deriving (Data,Typeable,Show)

instance Default AFile where def = AFile def False False

data ARMDir = ARMDir
    {rmDir :: Val
    ,rmRecursive :: Bool
    ,rmRebootOK :: Bool
    } deriving (Data,Typeable,Show)

instance Default ARMDir where def = ARMDir def False False

data ADelete = ADelete
    {delFile :: Val
    ,delRebootOK :: Bool
    } deriving (Data,Typeable,Show)

instance Default ADelete where def = ADelete def False

data HKEY
    = HKCR  | HKEY_CLASSES_ROOT
    | HKLM  | HKEY_LOCAL_MACHINE
    | HKCU  | HKEY_CURRENT_USER
    | HKU   | HKEY_USERS
    | HKCC  | HKEY_CURRENT_CONFIG
    | HKDD  | HKEY_DYN_DATA
    | HKPD  | HKEY_PERFORMANCE_DATA
    | SHCTX | SHELL_CONTEXT
     deriving (Show,Data,Typeable,Read,Bounded,Enum,Eq,Ord)

data MessageBoxType
    = MB_OK -- ^ Display with an OK button
    | MB_OKCANCEL -- ^ Display with an OK and a cancel button
    | MB_ABORTRETRYIGNORE -- ^ Display with abort, retry, ignore buttons
    | MB_RETRYCANCEL -- ^ Display with retry and cancel buttons
    | MB_YESNO -- ^ Display with yes and no buttons
    | MB_YESNOCANCEL -- ^ Display with yes, no, cancel buttons
    | MB_ICONEXCLAMATION -- ^ Display with exclamation icon
    | MB_ICONINFORMATION -- ^ Display with information icon
    | MB_ICONQUESTION -- ^ Display with question mark icon
    | MB_ICONSTOP -- ^ Display with stop icon
    | MB_USERICON -- ^ Display with installer's icon
    | MB_TOPMOST -- ^ Make messagebox topmost
    | MB_SETFOREGROUND -- ^ Set foreground
    | MB_RIGHT -- ^ Right align text
    | MB_RTLREADING -- ^ RTL reading order
    | MB_DEFBUTTON1 -- ^ Button 1 is default
    | MB_DEFBUTTON2 -- ^ Button 2 is default
    | MB_DEFBUTTON3 -- ^ Button 3 is default
    | MB_DEFBUTTON4 -- ^ Button 4 is default
     deriving (Show,Data,Typeable,Read,Bounded,Enum,Eq,Ord)
instance Default MessageBoxType where def = MB_ICONINFORMATION


data Page
    = License
    | Components
    | Directory
    | InstFiles
    | Confirm
     deriving (Show,Data,Typeable,Read,Bounded,Enum,Eq,Ord)

data Level = None | User | Highest | Admin
     deriving (Show,Data,Typeable,Read,Bounded,Enum,Eq,Ord)

data Visibility = Hide | Show | NeverShow
     deriving (Show,Data,Typeable,Read,Bounded,Enum,Eq,Ord)