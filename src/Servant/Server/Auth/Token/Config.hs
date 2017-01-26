{-|
Module      : Servant.Server.Auth.Token.Config
Description : Configuration of auth server
Copyright   : (c) Anton Gushcha, 2016
License     : MIT
Maintainer  : ncrashed@gmail.com
Stability   : experimental
Portability : Portable
-}
module Servant.Server.Auth.Token.Config(
    AuthConfig(..)
  , defaultAuthConfig
  ) where

import Control.Monad.IO.Class
import Data.Text (Text)
import Data.Time
import Data.UUID
import Data.UUID.V4
import Servant.Server

import Servant.API.Auth.Token

-- | Configuration specific for authorisation system
data AuthConfig db = AuthConfig {
  -- | Get storage that is used to run DB operations
    getDB :: !db
  -- | For authorisation, defines amounts of seconds
  -- when token becomes invalid.
  , defaultExpire :: !NominalDiffTime
  -- | For password restore, defines amounts of seconds
  -- when restore code becomes invalid.
  , restoreExpire :: !NominalDiffTime
  -- | User specified implementation of restore code sending. It could
  -- be a email sender or SMS message or mobile application method, whatever
  -- the implementation needs.
  , restoreCodeSender :: !(RespUserInfo -> RestoreCode -> IO ())
  -- | User specified generator for restore codes. By default the server
  -- generates UUID that can be unacceptable for SMS restoration routine.
  , restoreCodeGenerator :: !(IO RestoreCode)
  -- | Upper bound of expiration time that user can request
  -- for a token.
  , maximumExpire :: !(Maybe NominalDiffTime)
  -- | For authorisation, defines amount of hashing
  -- of new user passwords (should be greater or equal 14).
  -- The passwords hashed 2^strength times. It is needed to
  -- prevent almost all kinds of brute force attacks, rainbow
  -- tables and dictionary attacks.
  , passwordsStrength :: !Int
  -- | Validates user password at registration / password change.
  --
  -- If the function returns 'Just', then a 400 error is raised with
  -- specified text.
  --
  -- Default value doesn't validate passwords at all.
  , passwordValidator :: !(Text -> Maybe Text)
  -- | Transformation of errors produced by the auth server
  , servantErrorFormer :: !(ServantErr -> ServantErr)
  -- | Default size of page for pagination
  , defaultPageSize :: !Word
  -- | User specified method of sending single usage code for authorisation.
  --
  -- See also: endpoints 'AuthSigninGetCodeMethod' and 'AuthSigninPostCodeMethod'.
  --
  -- By default does nothing.
  , singleUseCodeSender :: !(RespUserInfo -> SingleUseCode -> IO ())
  -- | Time the generated single usage code expires after.
  --
  -- By default 1 hour.
  , singleUseCodeExpire :: !NominalDiffTime
  -- | User specified generator for single use codes.
  --
  -- By default the server generates UUID that can be unacceptable for SMS way of sending.
  , singleUseCodeGenerator :: !(IO SingleUseCode)
  -- | Number of not expiring single use codes that user can have at once.
  --
  -- Used by 'AuthGetSingleUseCodes' endpoint. Default is 100.
  , singleUseCodePermamentMaximum :: !Word
  -- | Number of not expiring single use codes that generated by default when client doesn't
  -- specify the value.
  --
  -- Used by 'AuthGetSingleUseCodes' endpoint. Default is 20.
  , singleUseCodeDefaultCount :: !Word
  }

-- | Default configuration for authorisation server
defaultAuthConfig :: db -> AuthConfig db
defaultAuthConfig db = AuthConfig {
    getDB = db
  , defaultExpire = fromIntegral (600 :: Int)
  , restoreExpire = fromIntegral (3*24*3600 :: Int) -- 3 days
  , restoreCodeSender = const $ const $ return ()
  , restoreCodeGenerator = uuidCodeGenerate
  , maximumExpire = Nothing
  , passwordsStrength = 17
  , passwordValidator = const Nothing
  , servantErrorFormer = id
  , defaultPageSize = 50
  , singleUseCodeSender = const $ const $ return ()
  , singleUseCodeExpire = fromIntegral (60 * 60 :: Int) -- 1 hour
  , singleUseCodeGenerator = uuidSingleUseCodeGenerate
  , singleUseCodePermamentMaximum = 100
  , singleUseCodeDefaultCount = 20
  }

-- | Default generator of restore codes
uuidCodeGenerate :: IO RestoreCode
uuidCodeGenerate = toText <$> liftIO nextRandom

-- | Default generator of restore codes
uuidSingleUseCodeGenerate :: IO RestoreCode
uuidSingleUseCodeGenerate = toText <$> liftIO nextRandom
