{-# LANGUAGE OverloadedStrings #-}
import Data.Monoid         ((<>))
import Hakyll
import Text.Pandoc.Options

main :: IO ()
main = hakyllWith config $ do
  match "images/*" $ do
    route   idRoute
    compile copyFileCompiler

  match "fonts/*" $ do
    route   idRoute
    compile copyFileCompiler

  match "css/*" $ do
    route   idRoute
    compile compressCssCompiler

  match (fromList ["ideas.html","future.html"]) $ do
    route idRoute
    compile $ do
      let ctx = defaultContext
      getResourceBody
        >>= loadAndApplyTemplate "templates/panel.html"   ctx
        >>= loadAndApplyTemplate "templates/default.html" ctx
        >>= relativizeUrls

  match "talks/*" $ do
    route $ setExtension "html"
    compile $ pandocCompilerWith
      (defaultHakyllReaderOptions
        { readerSmart = False
        , readerOldDashes = True
        })
      defaultHakyllWriterOptions
      >>= loadAndApplyTemplate "templates/talk.html"    talkCtx
      >>= loadAndApplyTemplate "templates/default.html" talkCtx
      >>= relativizeUrls

  create ["past.html"] $ do
    route idRoute
    compile $ do
      talks <- recentFirst =<< loadAll "talks/*"
      let talksCtx =
            listField "talks" talkCtx (return talks) <>
            constField "title" "Past Talks"          <>
            defaultContext

      makeItem ""
        >>= loadAndApplyTemplate "templates/past.html" talksCtx
        >>= loadAndApplyTemplate "templates/default.html" talksCtx
        >>= relativizeUrls


  match "index.html" $ do
    route idRoute
    compile $ do
      talks <- recentFirst =<< loadAll "talks/*"
      let indexCtx =
            listField "talks" talkCtx (return talks) <>
            defaultContext

      getResourceBody
        >>= applyAsTemplate indexCtx
        >>= loadAndApplyTemplate "templates/panel.html"   indexCtx
        >>= loadAndApplyTemplate "templates/default.html" indexCtx
        >>= relativizeUrls

  match "templates/*" $ compile templateCompiler

talkCtx :: Context String
talkCtx =
  dateField "date" "%B %e, %Y" <>
  defaultContext

config :: Configuration
config = defaultConfiguration
  { deployCommand = "cp -r ./_site/ ../talks-deploy && cd ../talks-deploy && git add -f . && git commit -m 'Deploying site' && git push"
  }
