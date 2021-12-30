component Main {
  style app {
    justify-content: center;
    flex-direction: column;
    align-items: center;
    display: flex;

    background-color: #282C34;
    height: 100vh;
    width: 100vw;

    font-family: Open Sans;
    font-weight: bold;
  }

  style label {
    margin: 10px;
    color: white;
    font-size: 20px;
  }

  style guessLabel {
    if (lastGuessValid) {
      font-size: 40px;
      text-transform: uppercase;
    } else {
      font-size: 24px;
    }
  }

  style guessField {
    height: 60px;
    font-size: 40px;
    width: 250px;
    margin-bottom: 20px;
    text-transform: uppercase;
  }

  style submit {
    height: 40px;
    font-size: 24px;
  }

  // Letters from previous guesses, styled to show whether they were correct or not
  style guessLetter(score : Score) {
    font-size: 40px;
    text-transform: uppercase;
    padding: 10px;
    margin: 2px;
    width: 60px;
    height: 60px;
    display: inline-block;
    text-align: center;
    color: white;
    vertical-align: center;
    
    case(score) {
      Score::Correct =>
        background: green;

      Score::Incorrect =>
        background: gray;
      
      Score::InWord =>
        background: orange;
    }
  }

  style footerLabel {
    font-weight: 400;
    font-size: 14px;
    color: white;
    position: fixed;
    bottom: 0;
    padding-bottom: 10px;
  }

  const CORRECT_LETTER_COUNT = 5

  // Words to choose a random answer from. Replace with your own words if you like!
  state words = ["noble", "paint", "weird", "world", "makes", "claim", "round", "smile"]
  state answer = ""
  
  state validationLabelText = ""
  state lastGuessValid = false
  
  state guessText = ""
  state letterScores: Array(LetterScore) = []
  state guesses: Array(Array(LetterScore)) = []

  fun render : Html {
    <div::app>

      if (Array.size(guesses) == 0) {
        <p::label>"Guess a five-letter word"</p>
      }

      <p::label::guessLabel>"#{validationLabelText}"</p>

      for (guess of guesses) {
        <div>
          for (score of guess) {
            <span::guessLetter(score.score)>"#{score.letter}"</span>
          }
        </div>
      }

      <p::label>"#{correct()} correct / #{inWord()} in word"</p>

      <input::guessField as input onChange={storeGuess} onKeyPress={handleKeyPress}>"Guess a word"</input>

      <button::submit onClick={validateGuess}>"Guess"</button>

      <footer::footerLabel>"Play the real "
        <Link href="https://www.powerlanguage.co.uk/wordle/">
        "Wordle"
        </Link>
      </footer>
    </div>
  }

  fun componentDidMount : Promise(Never, Void) {
    sequence {

      next { answer = 
        case (randomWord) {
          Maybe::Just(word) => word
          Maybe::Nothing => "chair"
        }
      }

      Dom.focus(input)
    }
  } where {
      randomWord = Array.sample(words)
  }

  fun handleKeyPress(event : Html.Event) : Promise(Never, Void) {
    case (event.key) {
      "Enter" => validateGuess()
      => next { }
    }
  }

  fun correct : Number {
    Array.select((score : LetterScore) : Bool { 
      case(score.score) {
        Score::Correct() => true
        => false
      }
    }, letterScores)
    |> Array.size()
  }

  fun inWord : Number {
    Array.select((score : LetterScore) : Bool {
      case(score.score) {
        Score::InWord() => true
        Score::Correct() => true
        => false
      }
    }, letterScores)
    |> Array.size()
  }

  fun storeGuess(event : Html.Event) : Promise(Never, Void) {
    next { guessText = text }
  } where {
    text = event.target |> Dom.getValue() |> String.replace(" ", "")
  }

  fun validateGuess : Promise(Never, Void) {
    sequence {

      case(input) {
        Maybe::Just(element) =>
        sequence {
          Dom.setValue("", element)
          next { }
        }
        Maybe::Nothing => next { }
      }

      next {
        lastGuessValid = 
          case(stateOf(guessText)) {
            GuessState::InvalidCharacterCount(count) => false
            GuessState::Correct => false
            GuessState::Incorrect => true
          }
      }

      next {
        letterScores =
        if (chars == 5) {
          check(guessText)
        } else {
          []
        }
      }

      next { guesses = Array.push(letterScores, guesses) }

      chars = String.size(guessText)

      next {
         validationLabelText = 
          if (chars != 5) {
            "#{guessText} has #{chars} letters. Please guess a 5-letter word."
          } else if (guessText == answer) {
            "You got it! That took #{Array.size(guesses)} guesses."
          } else {
            ""
          }
      }
    }
  }

  fun check(guess : String) : Array(LetterScore) {
    for (letter of letters) {
      if (String.match(letter, answer)) {
        if (Array.indexOf(letter, String.toArray(answer)) == Array.indexOf(letter, letters)) {
          LetterScore(letter, Score::Correct)
        } else {
          LetterScore(letter, Score::InWord)
        }
      } else {
        LetterScore(letter, Score::Incorrect)
      }
    }
  } where {
    letters = String.toArray(guess)
  }

  fun validCharacterCount(guess : String) : Bool {
    chars == CORRECT_LETTER_COUNT
  } where {
    chars = String.size(guess)
  }

  fun stateOf(guess : String) : GuessState {
    if (!validCharacterCount(guess)) {
      GuessState::InvalidCharacterCount(chars)
    } else if (guess == answer) {
      GuessState::Correct
    } else {
      GuessState::Incorrect
    }
  }

}

record LetterScore {
  letter : String,
  score : Score
}

enum Score {
  Correct()
  InWord()
  Incorrect()
}

enum GuessState {
  Correct
  Incorrect
  InvalidCharacterCount(Number)
}