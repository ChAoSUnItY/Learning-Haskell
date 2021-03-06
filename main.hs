module Main where

import Control.Applicative
import Data.Char

data JsonValue 
    = JsonNull
    | JsonBool Bool
    | JsonNumber Integer
    | JsonString String
    | JsonArray [JsonValue]
    | JsonObject [(String, JsonValue)]
    deriving (Show, Eq)

newtype Parser a = Parser
    { runParser :: String -> Maybe (String, a)
    }

instance Functor Parser where
    fmap f (Parser p) =
        Parser $ \input -> do
            (input', x) <- p input
            Just (input', f x)

instance Applicative Parser where
    pure x = Parser $ \input -> Just (input, x)
    (Parser p1) <*> (Parser p2) = Parser $ \input -> do
        (input', f)  <- p1 input
        (input'', a) <- p2 input'
        Just (input'', f a)

instance Alternative Parser where
    empty = Parser $ \_ -> Nothing
    (Parser p1) <|> (Parser p2) = Parser $ \input -> 
        p1 input <|> p2 input

charP :: Char -> Parser Char
charP x = Parser f
    where 
        f (y:ys)
            | y == x    = Just (ys, x)
            | otherwise = Nothing
        f []            = Nothing

stringP :: String -> Parser String
stringP = sequenceA . map charP

spanP :: (Char -> Bool) -> Parser String
spanP f = 
    Parser $ \input -> 
        let (token, rest) = span f input 
        in Just (rest, token)

notNull :: Parser [a] -> Parser [a]
notNull (Parser p) =
    Parser $ \input -> do
        (input', xs) <- p input
        if null xs
            then Nothing
            else Just (input', xs)

jsonNull :: Parser JsonValue
jsonNull = (\_ -> JsonNull) <$> stringP "null"

jsonBool :: Parser JsonValue
jsonBool = f <$> (stringP "true" <|> stringP "false")
    where f "true"  = JsonBool True
          f "false" = JsonBool False
          -- Exhausive branch should not never executed
          f _       = undefined

jsonNumber :: Parser JsonValue
jsonNumber = f <$> spanP isDigit
    where f ds = JsonNumber $ read ds

jsonString :: Parser String
jsonString = 

jsonValue :: Parser JsonValue
jsonValue = jsonNull <|> jsonBool <|> jsonNumber

main :: IO ()
main = putStrLn "hi"
