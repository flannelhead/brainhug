{-# LANGUAGE InstanceSigs #-}

module SimpleParser where

import Data.Monoid

data Parser a = Parser { runParser :: String -> Maybe (a, String) }

instance Functor Parser where
    fmap :: (a -> b) -> Parser a -> Parser b
    fmap f p = Parser $ \s -> (\(a, s1) -> (f a, s1)) <$> runParser p s

instance Applicative Parser where
    pure :: a -> Parser a
    pure x = Parser $ \s -> Just (x, s)

    (<*>) :: Parser (a -> b) -> Parser a -> Parser b
    pf <*> px = Parser $ \s -> runParser pf s  >>= (\(f, s1) ->
                               runParser px s1 >>= (\(x, s2) ->
                                   return (f x, s2)))

instance Monoid (Parser a) where
    mempty = Parser $ const Nothing
    mappend p1 p2 = Parser $ \s -> case runParser p1 s of
                                     Just a -> Just a
                                     _      -> runParser p2 s

skipMany :: Parser a -> Parser ()
skipMany p = (p *> skipMany p) <> pure ()

noneOf :: [Char] -> Parser Char
noneOf cs = satisfy (`notElem` cs)

satisfy :: (Char -> Bool) -> Parser Char
satisfy f = Parser $ \s -> case s of (c:cs) -> if f c then Just (c, cs)
                                                      else Nothing
                                     _      -> Nothing

char :: Char -> Parser Char
char c = satisfy (== c)

between :: Parser a -> Parser a -> Parser b -> Parser b
between open close p = open *> p <* close

(<|>) :: Monoid m => m -> m -> m
(<|>) = mappend
infixr 1 <|>

parse :: Parser a -> String -> String -> Either String a
parse p _ str = case runParser p str of
                  Nothing     -> Left "Parse error"
                  Just (x, _) -> Right x
